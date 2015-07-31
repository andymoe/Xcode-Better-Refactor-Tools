#import "XMASRefactorMethodAction.h"
#import <ClangKit/ClangKit.h>
#import "XMASAlert.h"
#import "XcodeInterfaces.h"
#import "XMASObjcMethodDeclaration.h"
#import "XMASObjcMethodDeclarationParser.h"
#import "XMASChangeMethodSignatureController.h"
#import "XMASChangeMethodSignatureControllerProvider.h"
#import "XMASXcode.h"
#import <objc/runtime.h>

NSString * const noMethodSelected = @"No method selected. Put your cursor inside of a method declaration";

@interface XMASRefactorMethodAction () <XMASChangeMethodSignatureControllerDelegate>
@property (nonatomic) id currentEditor;
@property (nonatomic) XMASAlert *alerter;
@property (nonatomic) XMASChangeMethodSignatureControllerProvider *controllerProvider;
@property (nonatomic) XMASObjcMethodDeclarationParser *methodDeclParser;

@property (nonatomic) XMASChangeMethodSignatureController *controller;

@end

@implementation XMASRefactorMethodAction

- (instancetype)initWithAlerter:(XMASAlert *)alerter
             controllerProvider:(XMASChangeMethodSignatureControllerProvider *)controllerProvider
               methodDeclParser:(XMASObjcMethodDeclarationParser *)methodDeclParser {
    if (self = [super init]) {
        self.alerter = alerter;
        self.controllerProvider = controllerProvider;
        self.methodDeclParser = methodDeclParser;
    }

    return self;
}

- (void)setupWithEditor:(id)editor {
    self.currentEditor = editor;
}

- (void)hackyGetClangArgsForBuildables {
    XC(Workspace) workspace = [XMASXcode currentWorkspace];

    for (id target in [workspace referencedBlueprints]) {
        unsigned int countOfMethods = 0;
//        Class targetClass = [target class];
//        Method *methods = class_copyMethodList(targetClass, &countOfMethods);
//        for (NSUInteger index = 0; index < countOfMethods; ++index) {
//            NSLog(@"================> %s", sel_getName(method_getName(methods[index])));
//        }

        // actual target
        NSLog(@"================> %@", target);
        // references to the filepaths that are its translation units (Xcode3FileReference)
        NSLog(@"================> %@", [target allBuildFileReferences]);

        // inspecting build context, trying to find -I and -F flags
        countOfMethods = 0;
        id context = [target valueForKey:@"targetBuildContext"];
        Class contextClass = [context class];
        Method *methods = class_copyMethodList(contextClass, &countOfMethods);
        for (NSUInteger index = 0; index < countOfMethods; ++index) {
            NSLog(@"================> %s", sel_getName(method_getName(methods[index])));
        }

        id badScope = [[NSClassFromString(@"XCMacroExpansionScope") alloc] init];
        NSLog(@"================> effective lib search paths %lu", [[context effectiveLibrarySearchPathsWithMacroExpansionScope:badScope] count]);

//        NSLog(@"================> %@", [context effectiveLibrarySearchPaths]);
//        NSLog(@"================> %@", [context effectiveFrameworkSearchPaths]);
//        NSLog(@"================> %@", [context effectiveUserHeaderSearchPaths]);
//        NSLog(@"================> %@", [context effectiveHeaderSearchPaths]);



//        id primaryBuildable = [target primaryBuildable];
//
//        if ([primaryBuildable conformsToProtocol:NSProtocolFromString(@"IDEBuildableProduct")]) {
//            NSLog(@"================> ZOMGGGGG primary buildable IS BUILDABLE");
//            NSLog(@"================> %@", [primaryBuildable valueForKey:@"productSettings"]);
//        }
//
//        NSLog(@"================> %@", [target primaryBuildable]);
//        NSLog(@"================> %@", [target buildables]);
//        NSLog(@"================> %@", [target buildableProducts]);
//        NSLog(@"================> %@", [target indexableFiles]);

        break;
    }

//    XC(RunContextManager) runContextManager = [workspace runContextManager];
//    NSArray *schemes = [runContextManager runContexts];
//
//    NSLog(@"================> found some schemes :: %@", schemes);
//    for (XC(IDEScheme) scheme in schemes) {
//        XC(IDEBuildSchemeAction) buildAction = [scheme buildSchemeAction];
//        NSLog(@"================> %@", buildAction);
//
//        NSArray *buildableReferences = [buildAction buildableReferences];
//        for (XC(IDESchemeBuildableReference) buildableRef in buildableReferences) {
//
//        }
//    }
}

- (void)safelyRefactorMethodUnderCursor {

    [self hackyGetClangArgsForBuildables];

    @try {
        [self refactorMethodUnderCursor];
    }
    @catch (NSException *exception) {
        [self.alerter flashComfortingMessageForException:exception];
    }
}

- (void)refactorMethodUnderCursor {
    NSUInteger cursorLocation = [self cursorLocation];
    NSString *currentFilePath = [self currentSourceCodeFilePath];
    NSString *currentFileContents = [NSString stringWithContentsOfFile:currentFilePath
                                                              encoding:NSUTF8StringEncoding
                                                                 error:nil];
    CKTranslationUnit *translationUnit = [CKTranslationUnit translationUnitWithText:currentFileContents
                                                                           language:CKLanguageObjCPP];
    NSArray *selectors = [self.methodDeclParser parseMethodDeclarationsFromTokens:translationUnit.tokens];

    XMASObjcMethodDeclaration *selectedMethod;
    for (XMASObjcMethodDeclaration *selector in selectors) {
        if (cursorLocation > selector.range.location && cursorLocation < selector.range.location + selector.range.length) {
            selectedMethod = selector;
            break;
        }
    }

    if (!selectedMethod) {
        [self.alerter flashMessage:noMethodSelected];
        return;
    }

    self.controller = [self.controllerProvider provideInstanceWithDelegate:self];
    [self.controller refactorMethod:selectedMethod inFile:currentFilePath];
}

#pragma mark - <XMASChangeMethodSignatureControllerDelegate>

- (void)controllerWillDisappear:(XMASChangeMethodSignatureController *)controller {
    self.controller = nil;
}

#pragma mark - editor helpers

- (NSString *)currentSourceCodeFilePath {
    if ([self.currentEditor respondsToSelector:@selector(sourceCodeDocument)]) {
        return [[[self.currentEditor sourceCodeDocument] fileURL] path];
    }
    return nil;
}

- (NSUInteger)cursorLocation {
    XC(DVTTextDocumentLocation) currentLocation = [[self.currentEditor currentSelectedDocumentLocations] lastObject];
    return currentLocation.characterRange.location;
}

#pragma mark - NSObject

- (instancetype)init {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

@end
