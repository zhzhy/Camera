//
//  CameraFileManager.m
//  RosyWriter
//
//  Created by zcy on 12-12-20.
//
//

#import "FoldManager.h"

@implementation FoldManager

+ (BOOL)isDirectoryExists:(NSString *)filePath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    return [fileManager fileExistsAtPath:filePath];
}

+ (BOOL)removeFileAtPath:(NSString *)filePath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    return [fileManager removeItemAtPath:filePath error:nil];
}

+ (NSString *)temporaryMovieFilePath
{
    return [NSTemporaryDirectory() stringByAppendingPathComponent:@"movie.mov"];
}
@end
