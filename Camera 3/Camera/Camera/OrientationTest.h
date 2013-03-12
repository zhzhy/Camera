//
//  OrientationTest.h
//  Camera
//
//  Created by zcy on 12-12-20.
//
//

#import <Foundation/Foundation.h>

@interface OrientationTest : NSObject
+ (BOOL)isInPortrait:(UIInterfaceOrientation)newOritention oldOrientatent:(UIInterfaceOrientation)oldOrientation;
+ (BOOL)isInLandscape:(UIInterfaceOrientation)newOritention oldOrientation:(UIInterfaceOrientation)oldOrientation;
+ (BOOL)isInSameInterface:(UIInterfaceOrientation)newOritention oldOrientation:(UIInterfaceOrientation)oldOrientation;
@end
