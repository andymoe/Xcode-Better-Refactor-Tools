#import <Foundation/Foundation.h>

@interface XMASObjcMethodCall : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithSelectorComponents:(NSArray *)selectorComponents
                                 arguments:(NSArray *)arguments
                                  filePath:(NSString *)filePath
                                     range:(NSRange)range NS_DESIGNATED_INITIALIZER;

- (NSArray *)selectorComponents;
- (NSString *)selectorString;
- (NSString *)filePath;
- (NSArray *)arguments;
- (NSRange)range;

@end
