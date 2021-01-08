/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBProcessLaunchConfiguration.h"
#import "FBProcessOutputConfiguration.h"

#import <FBControlCore/FBControlCore.h>

static NSString *const FailIfRunning = @"fail_if_running";
static NSString *const ForegroundIfRunning = @"foreground_if_running";
static NSString *const RelaunchIfRunning = @"foreground_if_running";

static NSString *LaunchModeStringFromLaunchMode(FBApplicationLaunchMode launchMode)
{
  switch (launchMode){
    case FBApplicationLaunchModeFailIfRunning:
      return FailIfRunning;
    case FBApplicationLaunchModeForegroundIfRunning:
      return ForegroundIfRunning;
    case FBApplicationLaunchModeRelaunchIfRunning:
      return RelaunchIfRunning;
    default:
      return @"unknown";
  }
}

static NSString *const KeyBundleID = @"bundle_id";
static NSString *const KeyBundleName = @"bundle_name";
static NSString *const KeyWaitForDebugger = @"wait_for_debugger";
static NSString *const KeyLaunchMode = @"launch_mode";

@implementation FBApplicationLaunchConfiguration

+ (instancetype)configurationWithApplication:(FBBundleDescriptor *)application arguments:(NSArray<NSString *> *)arguments environment:(NSDictionary<NSString *, NSString *> *)environment waitForDebugger:(BOOL)waitForDebugger output:(FBProcessOutputConfiguration *)output
{
  return [self configurationWithBundleID:application.identifier bundleName:application.name arguments:arguments environment:environment output:output launchMode:FBApplicationLaunchModeFailIfRunning];
}

+ (instancetype)configurationWithBundleID:(NSString *)bundleID bundleName:(NSString *)bundleName arguments:(NSArray<NSString *> *)arguments environment:(NSDictionary<NSString *, NSString *> *)environment waitForDebugger:(BOOL)waitForDebugger output:(FBProcessOutputConfiguration *)output
{
  return [[self alloc] initWithBundleID:bundleID bundleName:bundleName arguments:arguments environment:environment waitForDebugger:waitForDebugger output:output launchMode:FBApplicationLaunchModeFailIfRunning];
}

+ (instancetype)configurationWithBundleID:(NSString *)bundleID bundleName:(nullable NSString *)bundleName arguments:(NSArray<NSString *> *)arguments environment:(NSDictionary<NSString *, NSString *> *)environment output:(FBProcessOutputConfiguration *)output launchMode:(FBApplicationLaunchMode)launchMode
{
  if (!bundleID || !arguments || !environment) {
    return nil;
  }

  return [[self alloc] initWithBundleID:bundleID bundleName:bundleName arguments:arguments environment:environment waitForDebugger:NO output:output launchMode:launchMode];
}

- (instancetype)initWithBundleID:(NSString *)bundleID bundleName:(nullable NSString *)bundleName arguments:(NSArray<NSString *> *)arguments environment:(NSDictionary<NSString *, NSString *> *)environment waitForDebugger:(BOOL)waitForDebugger output:(FBProcessOutputConfiguration *)output launchMode:(FBApplicationLaunchMode)launchMode
{
  self = [super initWithArguments:arguments environment:environment output:output];
  if (!self) {
    return nil;
  }

  _bundleID = bundleID;
  _bundleName = bundleName;
  _waitForDebugger = waitForDebugger;
  _launchMode = launchMode;

  return self;
}

- (instancetype)withWaitForDebugger:(NSError **)error
{
  if (self.launchMode == FBApplicationLaunchModeForegroundIfRunning) {
    return [[FBControlCoreError
      describe:@"Can't wait for a debugger when launchMode = FBApplicationLaunchModeForegroundIfRunning"]
      fail:error];
  }
  return [[FBApplicationLaunchConfiguration alloc]
    initWithBundleID:self.bundleID
    bundleName:self.bundleName
    arguments:self.arguments
    environment:self.environment
    waitForDebugger:YES
    output:self.output
    launchMode:self.launchMode];
}

- (instancetype)withOutput:(FBProcessOutputConfiguration *)output
{
  return [[FBApplicationLaunchConfiguration alloc]
    initWithBundleID:self.bundleID
    bundleName:self.bundleName
    arguments:self.arguments
    environment:self.environment
    waitForDebugger:self.waitForDebugger
    output:output
    launchMode:self.launchMode];
}

#pragma mark Abstract Methods

- (NSString *)debugDescription
{
  return [NSString stringWithFormat:
    @"%@ | Arguments %@ | Environment %@ | WaitForDebugger %@ | LaunchMode %@ | Output %@",
    self.shortDescription,
    [FBCollectionInformation oneLineDescriptionFromArray:self.arguments],
    [FBCollectionInformation oneLineDescriptionFromDictionary:self.environment],
    self.waitForDebugger != 0 ? @"YES" : @"NO",
    LaunchModeStringFromLaunchMode(self.launchMode),
    self.output
  ];
}

- (NSString *)shortDescription
{
  return [NSString stringWithFormat:@"App Launch %@ (%@)", self.bundleID, self.bundleName];
}

#pragma mark NSCopying

- (instancetype)copyWithZone:(NSZone *)zone
{
  return [[self.class alloc]
    initWithBundleID:self.bundleID
    bundleName:self.bundleName
    arguments:self.arguments
    environment:self.environment
    waitForDebugger:self.waitForDebugger
    output:self.output
    launchMode:self.launchMode];
}

#pragma mark NSObject

- (NSUInteger)hash
{
  return [super hash] ^ self.bundleID.hash ^ self.bundleName.hash + (self.waitForDebugger ? 1231 : 1237);
}

- (BOOL)isEqual:(FBApplicationLaunchConfiguration *)object
{
  return [super isEqual:object] &&
    [self.bundleID isEqualToString:object.bundleID] &&
    (self.bundleName == object.bundleName || [self.bundleName isEqual:object.bundleName]) &&
    self.waitForDebugger == self.waitForDebugger &&
    self.launchMode == object.launchMode;

}

@end
