/* Part of LogicMOO Base logicmoo_util_bb_env
% Provides a prolog database *env*
% ===================================================================
% File '$FILENAME.pl'
% Purpose: An Implementation in SWI-Prolog of certain debugging tools
% Maintainer: Douglas Miles
% Contact: $Author: dmiles $@users.sourceforge.net ;
% Version: '$FILENAME.pl' 1.0.0
% Revision: $Revision: 1.1 $
% Revised At:  $Date: 2002/07/11 21:57:28 $
% Licience: LGPL
% ===================================================================
*/

% File: /opt/PrologMUD/pack/logicmoo_base/prolog/logicmoo/util/logicmoo_util_structs.pl
:- module(retry_undefined,
[	% uses_predicate/3,
                uses_undefined_hook/0,
                install_retry_undefined/0,
				% uses_predicate/5,
			   %     retry_undefined/3,
				is_parent_goal/1,
				is_parent_goal/2,
				has_parent_goal/1,
				has_parent_goal/2
]).

:- thread_local(was_prolog_flag/1).
:- current_prolog_flag(retry_undefined,Was)->asserta(was_prolog_flag(retry_undefined,Was));asserta(was_prolog_flag(retry_undefined,none)).
:- create_prolog_flag(retry_undefined, none,[type(term),keep(false)]).

:- module_transparent((	uses_predicate/2,
uses_undefined_hook/0,				uses_predicate/5,
				retry_undefined/3,
				is_parent_goal/1,
				is_parent_goal/2,
				has_parent_goal/1,
				has_parent_goal/2)).

install_retry_undefined.
uses_undefined_hook.

:- use_module(library(hook_database)).

 :- meta_predicate uses_predicate_new(*,*,*,*,*,*).
 :- meta_predicate uses_predicate(*,*,*,*,*,*).



dumpST_dbreak:- dumpST,break.

% baseKBOnly mark_mark/3 must be findable from every module (dispite the fact that baseKB is not imported)
:- dynamic baseKB:mpred_prop/4.

% hybrid_support (like spft/3) must be defined directly in every module and then aggregated thru genlMts (thus to baseKB)

:- dynamic(lmcache:tried_to_retry_undefined/4).

%uses_predicate(_DEF,M:F/A,R):- !, '$current_source_module'(SM), uses_predicate(_DEF,SM,M,F,A,R).
%uses_predicate(_DEF,F/A,R):- '$current_source_module'(SM),'context_module'(M),uses_predicate(_DEF,SM,M,F,A,R).

% uses_predicate_new(_Was,_CM,_M,_F,_A,Error):- is_parent_goal(check:check),!,Error=error.

 uses_predicate_new(_Was,_CM,_M,_F,_A,Error):- show_success(is_parent_goal('$define_predicate')),!,Error=error.


uses_predicate_new(Was,CM,M,F,A,Action):-
 setup_call_cleanup(set_prolog_flag(retry_undefined,false),
  show_failure(uses_predicate(Was,CM,M,F,A,Action)),
  set_prolog_flag(retry_undefined,Was)).

is_parent_goal(G):- prolog_current_frame(F),prolog_frame_attribute(F,parent_goal, G).
is_parent_goal(F,G):-prolog_frame_attribute(F,parent_goal, G).


has_parent_goal(G):- prolog_current_frame(F),prolog_frame_attribute(F,parent, PF),has_parent_goal(PF,G).
has_parent_goal(F,G):-prolog_frame_attribute(F,goal, G);(prolog_frame_attribute(F,parent, PF),has_parent_goal(PF,G)).

uses_predicate(_DEF,_, _, ~, 1, error) :- !.

uses_predicate(_DEF,_,CallerMt,'$pldoc',4,retry):- make_as_dynamic(uses_predicate,CallerMt,'$pldoc',4),!.
uses_predicate(_DEF,User, User, module, 2, error):-!.
uses_predicate(_DEF,_,_, (:-), _, error) :- !, fail. 
uses_predicate(_DEF,_,_, (/), _, error) :- !. 
uses_predicate(_DEF,_,_, (//), _, error) :- !. 
uses_predicate(_DEF,_,_, (:), _, error) :- !. % ,dumpST_dbreak.
% uses_predicate(_DEF,_,_, '[|]', _, error) :- !,dumpST_dbreak.
% uses_predicate(_DEF,_,_, '>>',  4, error) :- !,dumpST_dbreak.

uses_predicate(_DEF,_,M, inherit_above,_,retry):- M:use_module(library(virtualize_source)).

% makes sure we ignore calls to predicate_property/2  (or thus '$define_predicate'/1)
% uses_predicate(_DEF,_,M,F,A,R):- prolog_current_frame(FR), functor(P,F,A),(prolog_frame_attribute(FR,parent_goal,predicate_property(M:P,_))),!,R=error.
uses_predicate(_DEF,_,Module,Name,Arity,Action) :-
      current_prolog_flag(autoload, true),
	'$autoload'(Module, Name, Arity), !,
	Action = retry.

% make sure we ignore calls to predicate_property/2  (or thus '$define_predicate'/1)
uses_predicate(_DEF,_,_,_,_,error):- 
   prolog_current_frame(F),
  (is_parent_goal(F,'$define_predicate'(_));
   (fail,is_parent_goal(F,'assert_u'(_)));
   has_parent_goal(F,'$syspreds':property_predicate(_,_))),!.


uses_predicate(DEF,M, Var, F, A, Reply):- var(Var),nonvar(M),!,uses_predicate(DEF,M, M, F, A, Reply).

% keeps from calling this more than once
uses_predicate(DEF,SM,M,F,A,_Error):- 
  (lmcache:tried_to_retry_undefined(SM,M,F,A)-> 
    (wdmsg(re_used_predicate(SM,M,F,A)),fail) ;
    (wdmsg(uses_predicate(DEF,SM,M,F,A)),assert(lmcache:tried_to_retry_undefined(SM,M,F,A)))),
  fail.

uses_predicate(_DEF,_,System, _,_, error):- module_property(System,class(system)),!.
uses_predicate(_DEF,_,System, _,_, error):- module_property(System,class(library)),!.

uses_predicate(kb_shared,System, M, F,A, retry):- !,
   show_failure(uses_undefined_hook(M)),
   create_predicate_inheritance(M,F,A),
   nop(System:import(M:F/A)),!.

uses_predicate(DEF,System, M, F,A, retry):- 
   % uses_undefined_hook(M),
   call(DEF,M:F/A),
   create_predicate_inheritance(M,F,A),
   nop(System:import(M:F/A)),!.


uses_predicate(DEF,BaseKB,System, F,A,R):-   System\==BaseKB, 
  clause_b(mtHybrid(BaseKB)),\+ clause_b(mtHybrid(System)),!,dumpST,
   must(uses_predicate(DEF,System,BaseKB,F,A,R)),!.


uses_predicate(DEF,SM,CallerMt,F,A,R):- trace_or_throw(uses_predicate(DEF,SM,CallerMt,F,A,R)), break,
    loop_check_term(retry_undefined(CallerMt,F,A),dump_break_loop_check_uses_predicate(_DEF,SM,CallerMt,F,A,retry),dump_break),
    R=retry.


:- if(\+ current_predicate(autoload_library_index/4)).
in_autoload_library_index(F,A,_PredMt,File):- '$in_library'(F,A,File).
:- else.
in_autoload_library_index(F,A,PredMt,File):- autoload_library_index(F,A,PredMt,File).
:- endif.

:- meta_predicate with_no_retry_undefined(:).
with_no_retry_undefined(Goal):- locally(set_prolog_flag(retry_undefined, none),
                                     locally(flag_call(runtime_debug=false),Goal)).
      

% Every module has it''s own
retry_undefined(CallerMt,'$pldoc',4):- multifile(CallerMt:'$pldoc'/4),discontiguous(CallerMt:'$pldoc'/4),dynamic(CallerMt:'$pldoc'/4),!.

% 3 very special Mts
% Module defines the type
% retry_undefined(baseKB,F,A):- make_as_dynamic(retry_undefined(baseKB),baseKB,F,A),!.
retry_undefined(lmcache,F,A):- volatile(lmcache:F/A),make_as_dynamic(retry_undefined(lmcache),lmcache,F,A),!.
retry_undefined(t_l,F,A):- thread_local(t_l:F/A),!,make_as_dynamic(retry_undefined(t_l),t_l,F,A),!.

% adult-like Mt
retry_undefined(Mt, F, A):-  clause_b(mtCycLBroad(Mt)), clause_b(hybrid_support(F,A)),
   make_as_dynamic(mtCycLBroad(Mt),Mt,F,A).

% child-like Mt
retry_undefined(CallerMt,F,A):- clause_b(mtGlobal(CallerMt)), clause_b(hybrid_support(F,A)),
   % find_and_call(baseKB:mtGlobal(CallerMt)),
   create_predicate_inheritance(CallerMt,F,A).

% import built-ins ?
retry_undefined(CallerMt,F,A):- current_predicate(system:F/A), current_module(M),M\=system,
  current_predicate(M:F/A),functor(P,F,A),predicate_property(M:P,defined),\+predicate_property(M:P,imported_from(_)),
  CallerMt:import(M:F/A).

% our autoloader hacks
retry_undefined(CallerMt,F,A):-
   in_autoload_library_index(F,A,_PredMt,File),
   use_module(CallerMt:File),!.

% Autoloads importing the entire other module
retry_undefined(CallerMt,F,A):- fail,fail,fail,fail,fail,fail,fail,fail,fail,fail,fail,fail,fail,fail,fail,fail,fail,fail,fail,fail,
       in_autoload_library_index(F,A,PredMt,File),
       asserta(lmcache:how_registered_pred(PredMt:use_module(CallerMt:File),CallerMt,F,A)),
       use_module(system:File),!.
       % system:add_import_module(CallerMt,system,start).



% System-like Autoloads (TODO: confirm these can be removed)
retry_undefined(CallerMt,debug,1):- use_module(CallerMt:library(debug)),!.
retry_undefined(CallerMt,debugging,1):- use_module(CallerMt:library(debug)),!.
retry_undefined(CallerMt,member,2):- use_module(CallerMt:library(lists)),!.
retry_undefined(CallerMt,directory_file_path,3):- use_module(CallerMt:library(filesex)),!.


retry_undefined(CallerMt,F,A):- fail,
       in_autoload_library_index(F,A,_,File),
       load_files(CallerMt:File,[if(true),imports([F/A]),register(false),silent(false)]),!.

% Autoloads importing the entire other module
retry_undefined(CallerMt,F,A):- fail,fail,fail,fail,fail,fail,fail,fail,fail,fail,fail,fail,fail,fail,fail,fail,fail,fail,fail,fail,
       in_autoload_library_index(F,A,PredMt,File),
       asserta(lmcache:how_registered_pred(PredMt:use_module(CallerMt:File),CallerMt,F,A)),
       use_module(CallerMt:File),!.

/*
retry_undefined(CallerMt,F,A):-
      in_autoload_library_index(F,A,PredMt,File),
      ((current_module(PredMt),current_predicate(PredMt:F/A))
       -> add_import_module(CallerMt,PredMt,start) ;
       (PredMt:ensure_loaded(PredMt:File),add_import_module(CallerMt,PredMt,start))),!.
*/

retry_undefined(CallerMt,F,A):- fail,fail,fail,fail,fail,fail,fail,fail,fail,fail,fail,fail,fail,fail,fail,fail,fail,fail,fail,fail,
   functor(P,F,A),find_module(P,M),show_call(CallerMt:import(M:F/A)),!.


%retry_undefined(PredMt:must/1) % UNDO % :- add_import_module(PredMt,logicmoo_util_catch,start),!.
%retry_undefined(PredMt:debugm/2) % UNDO % :- add_import_module(PredMt,logicmoo_util_dmsg,start),!.

%uses_undefined_hook(CM):- (clause_b(genlMt(CM,_));clause_b(mtHybrid(CM))).
uses_undefined_hook(CM):- clause_b(genlMt(CM,_)),!.
% uses_undefined_hook(CM):- is_pfc_module(CM),!.
uses_undefined_hook(baseKB).
uses_undefined_hook(user).


:- fixup_exports.

:- multifile(prolog:make_hook/2).
:- dynamic(prolog:make_hook/2).
:- multifile(lmcache:was_retry_undefined/2).
:- dynamic(lmcache:was_retry_undefined/2).
:- dynamic(prolog:make_hook/2).
prolog:make_hook(before, C):- current_prolog_flag(retry_undefined, WAS),asserta(lmcache:was_retry_undefined(WAS,C)),set_prolog_flag(retry_undefined, fail),fail.
prolog:make_hook(after, C):- retract(lmcache:was_retry_undefined(WAS,C)),set_prolog_flag(retry_undefined, WAS),fail.

:- multifile(user:exception/3).
:- module_transparent(user:exception/3).
:- dynamic(user:exception/3).

user:exception(undefined_predicate, M:F/A, ActionO):- 
  \+ current_prolog_flag(retry_undefined, none), current_prolog_flag(retry_undefined, Was),
   Was \== false,
  strip_module(F/A,CM,_),
  uses_predicate_new(Was,CM,M,F,A, ActionO).

user:exception(undefined_predicate, F/A, ActionO):- 
  \+ current_prolog_flag(retry_undefined, none), current_prolog_flag(retry_undefined, Was),
   Was \== false,
  strip_module(F/A,CM,_),
  uses_predicate_new(Was,CM,CM,F,A, ActionO).

