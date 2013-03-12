//
//  CameraFileManager.h
//  Camera
//
//  Created by zcy on 12-12-20.
//
//

#import <Foundation/Foundation.h>

@interface FoldManager : NSObject
+ (BOOL)isDirectoryExists:(NSString *)filePath;
+ (BOOL)removeFileAtPath:(NSString *)filePath;
+ (NSString *)temporaryMovieFilePath;
@end
