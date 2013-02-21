//
//  OrientationTest.m
//  RosyWriter
//
//  Created by zcy on 12-12-20.
//
//

#import "OrientationTest.h"

@implementation OrientationTest

+ (BOOL)isInPortrait:(UIInterfaceOrientation)newOritention oldOrientatent:(UIInterfaceOrientation)oldOrientation
{
    if (newOritention >= UIInterfaceOrientationPortrait && newOritention <= UIInterfaceOrientationPortraitUpsideDown && oldOrientation >= UIInterfaceOrientationPortrait && oldOrientation <= UIInterfaceOrientationPortraitUpsideDown) {
        return YES;
    }
    return NO;
}

+ (BOOL)isInLandscape:(UIInterfaceOrientation)newOritention oldOrientation:(UIInterfaceOrientation)oldOrientation
{
    if (newOritention >= UIInterfaceOrientationLandscapeRight && newOritention <= UIInterfaceOrientationLandscapeLeft && oldOrientation >= UIInterfaceOrientationLandscapeRight && oldOrientation <= UIInterfaceOrientationLandscapeLeft) {
        return YES;
    }
    return NO;
}

+ (BOOL)isInSameInterface:(UIInterfaceOrientation)newOritention oldOrientation:(UIInterfaceOrientation)oldOrientation
{
    if ([OrientationTest isInPortrait:newOritention oldOrientatent:oldOrientation] || [OrientationTest isInLandscape:newOritention oldOrientation:oldOrientation]) {
        return YES;
    }
    return NO;
}
@end
