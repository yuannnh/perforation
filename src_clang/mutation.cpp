#include <iostream>
#include <sstream>
#include <string>

#include "clang/AST/AST.h"
#include "clang/AST/ASTConsumer.h"
#include "clang/AST/RecursiveASTVisitor.h"
#include "clang/Frontend/ASTConsumers.h"
#include "clang/Frontend/CompilerInstance.h"
#include "clang/Frontend/FrontendActions.h"
#include "clang/Rewrite/Core/Rewriter.h"
#include "clang/Tooling/CommonOptionsParser.h"
#include "clang/Tooling/Tooling.h"
#include "llvm/Support/raw_ostream.h"
#include "clang/AST/OperationKinds.def"

using namespace clang;
using namespace clang::driver;
using namespace clang::tooling;

int AIM = 0;
int COUNT = 0;
bool FIN  = false;



static llvm::cl::OptionCategory ToolingSampleCategory("Tooling Sample");


// By implementing RecursiveASTVisitor, we can specify which AST nodes
// we're interested in by overriding relevant methods.
class MyASTVisitor : public RecursiveASTVisitor<MyASTVisitor> {
public:
  MyASTVisitor(Rewriter &R) : TheRewriter(R) {}

  bool VisitStmt(Stmt *s) {
	if(AIM <0 && FIN!=true){
		operatorMut(s,TheRewriter);
		FIN = true;
	}
    AIM-=1;
    return true;
  }
  
  void operatorMut(Stmt *s, Rewriter &R){
		if (isa<BinaryOperator>(s)) {
			  BinaryOperator *BO = cast<BinaryOperator>(s);
			  std::string op = "";
			  std::string opr_str;
			  SourceRange range;
				
			  if(BO->isCompoundAssignmentOp()){
				  range = SourceRange(BO->getExprLoc(), BO->getExprLoc());
				  opr_str = BO->getOpcodeStr(BO->getOpcode()).data();
				  if(opr_str == "+="){
					  op = "-=";
				  }
				  else if(opr_str == "-="){
					  op = "+=";
				  }	
					  
			  }
			  else if(BO->isAssignmentOp()){
				  
				  //BO->setOpcode(BO_Mul);
				  range = SourceRange(BO->getRHS()->getExprLoc(), BO->getRHS()->getExprLoc());
				  BinaryOperator *opr = cast<BinaryOperator>(BO->getRHS());
				  if(isa<IntegerLiteral>(opr)){
					  op = "";
				  }
				  //opr_str = opr->getOpcodeStr(opr->getOpcode()).data();
				  else if(opr->getOpcode() == BO_Add){
					  op = "-";
				  }
				  else if(opr->getOpcode() == BO_Sub){
					  op = "+";
				  }
				  else if(opr->getOpcode() == BO_Mul){
					  op = "/";
				  }
				  else if(opr->getOpcode() == BO_Div){
					  op = "*";
				  }
				  
				  
			  }
			  if(op!=""){
				  TheRewriter.ReplaceText(range,op);
			  }
			  
			}
	
		}

private:
  Rewriter &TheRewriter;
 

};

// Implementation of the ASTConsumer interface for reading an AST produced
// by the Clang parser.
class MyASTConsumer : public ASTConsumer {
public:
  MyASTConsumer(Rewriter &R) : Visitor(R) {}

  // Override the method that gets called for each parsed top-level
  // declaration.
  bool HandleTopLevelDecl(DeclGroupRef DR) override {
    for (DeclGroupRef::iterator b = DR.begin(), e = DR.end(); b != e; ++b) {
      // Traverse the declaration using our AST visitor.
      Visitor.TraverseDecl(*b);
      (*b)->dump();
    }
    return COUNT;
  }

private:
  MyASTVisitor Visitor;
};

// For each source file provided to the tool, a new FrontendAction is created.
class MyFrontendAction : public ASTFrontendAction {
public:
  MyFrontendAction() {}
  void EndSourceFileAction() override {
    SourceManager &SM = TheRewriter.getSourceMgr();
    llvm::errs() << "** EndSourceFileAction for: "
                 << SM.getFileEntryForID(SM.getMainFileID())->getName() << "\n";

    // Now emit the rewritten buffer.
    TheRewriter.getEditBuffer(SM.getMainFileID()).write(llvm::outs());
  }

  std::unique_ptr<ASTConsumer> CreateASTConsumer(CompilerInstance &CI,
                                                 StringRef file) override {
    llvm::errs() << "** Creating AST consumer for: " << file << "\n";
    TheRewriter.setSourceMgr(CI.getSourceManager(), CI.getLangOpts());
    return llvm::make_unique<MyASTConsumer>(TheRewriter);
  }

private:
  Rewriter TheRewriter;
};

int main(int argc, const char **argv) {
  CommonOptionsParser op(argc, argv, ToolingSampleCategory);
  ClangTool Tool(op.getCompilations(), op.getSourcePathList());
  Tool.run(newFrontendActionFactory<MyFrontendAction>().get());
  AIM = rand()%COUNT;
  

  // ClangTool::run accepts a FrontendActionFactory, which is then used to
  // create new objects implementing the FrontendAction interface. Here we use
  // the helper newFrontendActionFactory to create a default factory that will
  // return a new MyFrontendAction object every time.
  // To further customize this, we could create our own factory class.
  return Tool.run(newFrontendActionFactory<MyFrontendAction>().get());
}
