#import <Foundation/Foundation.h>
#import <Blindside/Blindside.h>

@interface XMASEditMenu : NSObject
- (void)attach;
- (void)refactorCurrentMethodAction:(id)sender;

- (instancetype)initWithInjector:(id<BSInjector>)injector NS_DESIGNATED_INITIALIZER;
@end

@interface XMASEditMenu (UnavailableInitializers)
+ (instancetype)new;
- (instancetype)init;
@end
