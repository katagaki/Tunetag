#import <Foundation/Foundation.h>

@interface ID3DateWriter : NSObject

+ (BOOL)writeDate:(NSString *)date toMP3AtPath:(NSString *)path;

@end
