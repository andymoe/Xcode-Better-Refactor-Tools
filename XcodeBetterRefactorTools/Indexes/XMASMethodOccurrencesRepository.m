#import "XMASMethodOccurrencesRepository.h"
#import "XMASObjcMethodDeclaration.h"
#import "XcodeInterfaces.h"
#import "XMASXcode.h"

@interface XMASMethodOccurrencesRepository ()
@property (nonatomic) XC(IDEWorkspaceWindowController) workspaceWindowController;
@end

@implementation XMASMethodOccurrencesRepository

- (instancetype)initWithWorkspaceWindowController:(XC(IDEWorkspaceWindowController))workspaceWindowController {
    if (self = [super init]) {
        self.workspaceWindowController = workspaceWindowController;
    }

    return self;
}

- (NSArray *)callSitesOfCurrentlySelectedMethod {
    id editorContext = [[self.workspaceWindowController editorArea] lastActiveEditorContext];
    NSArray *geniusSourceCodeCallerResults = [XMASXcode geniusCallerResultsForEditorContext:editorContext];

    NSMutableArray *results = [[NSMutableArray alloc] init];
    for (XC(IDESourceCodeCallerGeniusResult) sourceCodeCallerResult in geniusSourceCodeCallerResults) {
        [results addObject:[sourceCodeCallerResult valueForKey:@"calleeSymbolOccurrence"]];
    }

    return results;
}

- (NSArray *)forwardDeclarationsOfMethod:(XMASObjcMethodDeclaration *)methodDeclaration {
    NSMutableArray *matchingSymbols = [[NSMutableArray alloc] init];
    NSArray *callableSymbols = [XMASXcode callableSymbolsInWorkspace];
    for (XC(IDEIndexSymbol) symbol in callableSymbols) {
        if ([[symbol name] isEqualToString:methodDeclaration.selectorString]) {
            [matchingSymbols addObject:symbol];
        }
    }

    return matchingSymbols;
}

@end