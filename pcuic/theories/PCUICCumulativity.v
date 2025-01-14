(* Distributed under the terms of the MIT license.   *)
From Equations Require Import Equations.
From Coq Require Import Bool String List Program BinPos Compare_dec Omega.
From MetaCoq.Template Require Import config utils AstUtils.
From MetaCoq.PCUIC Require Import PCUICAst PCUICAstUtils PCUICInduction
     PCUICLiftSubst PCUICUnivSubst PCUICTyping PCUICWeakeningEnv PCUICWeakening
     PCUICClosed PCUICReduction.
Require Import ssreflect ssrbool.
Require Import String.
From MetaCoq Require Import LibHypsNaming.
Local Open Scope string_scope.
Set Asymmetric Patterns.
Require Import CRelationClasses.
Require Import Equations.Type.Relation Equations.Type.Relation_Properties.

Reserved Notation " Σ ;;; Γ |- t == u " (at level 50, Γ, t, u at next level).

Lemma cumul_alt `{cf : checker_flags} Σ Γ t u :
  Σ ;;; Γ |- t <= u <~> { v & { v' & (red Σ Γ t v * red Σ Γ u v' * leq_term (global_ext_constraints Σ) v v')%type } }.
Proof.
  split.
  { induction 1. exists t, u. intuition auto; constructor.
    destruct IHX as (v' & v'' & (redv & redv') & leqv).
    exists v', v''. intuition auto. now eapply red_step.
    destruct IHX as (v' & v'' & (redv & redv') & leqv).
    exists v', v''. intuition auto. now eapply red_step. }
  { intros [v [v' [[redv redv'] Hleq]]]. apply red_alt in redv. apply red_alt in redv'.
    apply clos_rt_rt1n in redv.
    apply clos_rt_rt1n in redv'.
    induction redv. induction redv'. constructor; auto.
    econstructor 3; eauto.
    econstructor 2; eauto. }
Qed.

Lemma eq_term_upto_univ_refl Re Rle :
  CRelationClasses.Reflexive Re ->
  CRelationClasses.Reflexive Rle ->
  forall t, eq_term_upto_univ Re Rle t t.
Proof.
  intros hRe hRle.
  induction t in Rle, hRle |- * using term_forall_list_ind; simpl;
    try constructor; try solve [eapply All_All2; eauto]; try easy;
      try now apply All2_same.
  - destruct p. constructor; try easy.
    red in X. eapply All_All2; eauto.
  - eapply All_All2; eauto. simpl. intuition eauto.
  - eapply All_All2; eauto. simpl. intuition eauto.
Qed.

Lemma eq_term_refl `{checker_flags} φ t : eq_term φ t t.
Proof.
  apply eq_term_upto_univ_refl ; intro ; apply eq_universe_refl.
Qed.

Lemma leq_term_refl `{checker_flags} φ t : leq_term φ t t.
Proof.
  apply eq_term_upto_univ_refl.
  - intro ; apply eq_universe_refl.
  - intro ; apply leq_universe_refl.
Qed.

Lemma cumul_refl' {cf : checker_flags} Σ Γ t : Σ ;;; Γ |- t <= t.
Proof.
  eapply cumul_alt. exists t, t; intuition eauto. eapply leq_term_refl.
Qed.

Lemma conv_refl' {cf : checker_flags} Σ Γ t : Σ ;;; Γ |- t = t.
Proof.
  split; apply cumul_refl'.
Qed.

Lemma red_cumul `{cf : checker_flags} {Σ : global_env_ext} {Γ t u} :
  red Σ Γ t u ->
  Σ ;;; Γ |- t <= u.
Proof.
  intros. apply red_alt in X. apply clos_rt_rt1n in X.
  induction X. apply cumul_refl'.
  econstructor 2; eauto.
Qed.

Lemma red_cumul_inv `{cf : checker_flags} {Σ : global_env_ext} {Γ t u} :
  red Σ Γ t u ->
  Σ ;;; Γ |- u <= t.
Proof.
  intros. apply red_alt in X. apply clos_rt_rt1n in X.
  induction X. apply cumul_refl'.
  econstructor 3; eauto.
Qed.

Lemma red_cumul_cumul `{cf : checker_flags} {Σ : global_env_ext} {Γ t u v} :
  red Σ Γ t u -> Σ ;;; Γ |- u <= v -> Σ ;;; Γ |- t <= v.
Proof.
  intros. apply red_alt in X. apply clos_rt_rt1n in X.
  induction X. auto.
  econstructor 2; eauto.
Qed.

Lemma red_cumul_cumul_inv `{cf : checker_flags} {Σ : global_env_ext} {Γ t u v} :
  red Σ Γ t v -> Σ ;;; Γ |- u <= v -> Σ ;;; Γ |- u <= t.
Proof.
  intros. apply red_alt in X. apply clos_rt_rt1n in X.
  induction X. auto.
  econstructor 3. eapply IHX. eauto. eauto.
Qed.

Lemma red_conv {cf:checker_flags} (Σ : global_env_ext) Γ t u : red Σ Γ t u -> Σ ;;; Γ |- t = u.
Proof.
  intros. split; [apply red_cumul|apply red_cumul_inv]; auto.
Qed.

Lemma conv_cumul {cf:checker_flags} Σ Γ t u :
  Σ ;;; Γ |- t = u -> (Σ ;;; Γ |- t <= u) * (Σ ;;; Γ |- u <= t).
Proof. trivial. Qed.

Lemma All_All2_refl {A : Type} {R} {l : list A} : All (fun x : A => R x x) l -> All2 R l l.
Proof.
  induction 1; constructor; auto.
Qed.

Lemma eq_term_upto_univ_leq :
  forall (Re Rle : universe -> universe -> Type) u v,
    (forall u u', Re u u' -> Rle u u') ->
    eq_term_upto_univ Re Re u v ->
    eq_term_upto_univ Re Rle u v.
Proof.
  intros Re Rle u v hR h.
  induction u in v, h |- * using term_forall_list_ind.
  all: simpl ; inversion h ;
       subst ; constructor ; try easy.
  all: eapply All2_impl ; eauto.
Qed.

Lemma eq_term_leq_term `{checker_flags} φ t u : eq_term φ t u -> leq_term φ t u.
Proof.
  intros h. eapply eq_term_upto_univ_leq ; eauto.
  eapply eq_universe_leq_universe.
Qed.

Lemma eq_term_upto_univ_incl `{cf:checker_flags} Re Rle :
  inclusion Re Rle -> inclusion (eq_term_upto_univ Re Re) (eq_term_upto_univ Re Rle).
Proof. intros. intros x y H. eapply eq_term_upto_univ_leq in H; eauto. Qed.

Lemma eq_term_upto_univ_antisym :
  forall (Re Rle : universe -> universe -> Type) u v,
    (forall u u', Rle u u' -> Rle u' u -> Re u u') ->
    eq_term_upto_univ Re Rle u v ->
    eq_term_upto_univ Re Rle v u ->
    eq_term_upto_univ Re Re u v.
Proof.
  intros Re Rle u v hR h h'.
  induction u in v, h, h' |- * using term_forall_list_ind.
  all: simpl ; inversion h ; inversion h' ;
       subst ; try constructor ; try easy.
  all: try solve [eapply All2_impl ; eauto]; eauto.
  all: simpl ; inversion h ; inversion h' ;
       subst ; try constructor ; try easy.
  - noconf H. depelim h; depelim h'.
    eapply All2_sym in a.
    eapply All2_impl; [eapply All2_prod|]; [eapply a0|eapply a|].
    intros x y [xy yx]. auto.
  - noconf H. depelim h; depelim h'.
    eapply All2_sym in a.
    eapply All2_impl; [eapply All2_prod|]; [eapply a0|eapply a|].
    intros x y [xy yx]. auto.
  - noconf H. depelim h; depelim h'.
    eapply All2_sym in a.
    eapply All2_impl; [eapply All2_prod|]; [eapply a0|eapply a|].
    intros x y [xy yx]. auto.
Qed.

Lemma leq_term_antisym `{cf : checker_flags} (Σ : constraints) t u :
  leq_term Σ t u -> leq_term Σ u t -> eq_term Σ t u.
Proof.
  intros. eapply eq_term_upto_univ_antisym; [|eauto ..].
  eapply leq_universe_antisym.
Qed.

Lemma eq_term_App `{checker_flags} φ f f' :
  eq_term φ f f' ->
  isApp f = isApp f'.
Proof.
  inversion 1; reflexivity.
Qed.

Lemma eq_term_mkApps `{checker_flags} φ f l f' l' :
  eq_term φ f f' ->
  All2 (eq_term φ) l l' ->
  eq_term φ (mkApps f l) (mkApps f' l').
Proof.
  induction l in l', f, f' |- *; intro e; inversion_clear 1.
  - assumption.
  - cbn. eapply IHl. constructor; assumption. assumption.
Qed.

Lemma leq_term_App `{checker_flags} φ f f' :
  leq_term φ f f' ->
  isApp f = isApp f'.
Proof.
  inversion 1; reflexivity.
Qed.

Lemma leq_term_mkApps `{checker_flags} φ f l f' l' :
  leq_term φ f f' ->
  All2 (eq_term φ) l l' ->
  leq_term φ (mkApps f l) (mkApps f' l').
Proof.
  induction l in l', f, f' |- *; intro e; inversion_clear 1.
  - assumption.
  - cbn. apply IHl. constructor; try assumption. assumption.
Qed.

Lemma eq_term_upto_univ_sym :
  forall Re Rle,
    CRelationClasses.Symmetric Re ->
    CRelationClasses.Symmetric Rle ->
    CRelationClasses.Symmetric (eq_term_upto_univ Re Rle).
Proof.
  intros Re Rle he hle u v e.
  induction u in Rle, hle, v, e |- * using term_forall_list_ind.
  all: dependent destruction e.
  all: try solve [
    econstructor ; eauto ;
    try eapply All2_symP ; eauto
  ].
  - econstructor.
    eapply All2_All_mix_left in X as h; eauto.
    clear a X.
    induction h.
    + constructor.
    + destruct r as [h1 h2]. eapply h1 in h2 ; auto.
  - econstructor; eauto.
    eapply All2_All_mix_left in X as h; eauto.
    clear a X.
    induction h.
    + constructor.
    + destruct r as [h1 [h2 h3]]. eapply h1 in h3 ; auto.
  - econstructor.
    eapply All2_All_mix_left in X as h; eauto.
    clear a X.
    induction h.
    + constructor.
    + destruct r as [[h1 h2] [[h3 h4] h5]].
      eapply h1 in h3 ; auto.
  - econstructor.
    eapply All2_All_mix_left in X as h; eauto.
    clear a X.
    induction h.
    + constructor.
    + destruct r as [[h1 h2] [[h3 h4] h5]]. eapply h1 in h3 ; auto.
Qed.

Corollary eq_term_sym `{checker_flags} :
  forall G t u,
    eq_term G t u ->
    eq_term G u t.
Proof.
  intros G t u h.
  eapply eq_term_upto_univ_sym ; eauto.
  all: intros ? ? ? ; eapply eq_universe_sym ; eauto.
Qed.

Inductive conv_alt `{checker_flags} (Σ : global_env_ext) (Γ : context) : term -> term -> Type :=
| conv_alt_refl t u : eq_term (global_ext_constraints Σ) t u -> Σ ;;; Γ |- t == u
| conv_alt_red_l t u v : red1 Σ Γ t v -> Σ ;;; Γ |- v == u -> Σ ;;; Γ |- t == u
| conv_alt_red_r t u v : Σ ;;; Γ |- t == v -> red1 (fst Σ) Γ u v -> Σ ;;; Γ |- t == u
where " Σ ;;; Γ |- t == u " := (@conv_alt _ Σ Γ t u) : type_scope.

Lemma red_conv_alt `{cf : checker_flags} Σ Γ t u :
  red (fst Σ) Γ t u ->
  Σ ;;; Γ |- t == u.
Proof.
  intros. apply red_alt in X. apply clos_rt_rt1n_iff in X.
  induction X. constructor. apply eq_term_refl.
  apply clos_rt_rt1n_iff in X. apply red_alt in X.
  econstructor 2; eauto.
Qed.
Hint Resolve red_conv_alt.

Hint Resolve leq_term_refl cumul_refl' : core.

Lemma red_conv_conv `{cf : checker_flags} Σ Γ t u v :
  red (fst Σ) Γ t u -> Σ ;;; Γ |- u == v -> Σ ;;; Γ |- t == v.
Proof.
  intros. apply red_alt in X. apply clos_rt_rt1n_iff in X.
  induction X; auto.
  econstructor 2; eauto.
Qed.

Lemma red_conv_conv_inv `{cf : checker_flags} Σ Γ t u v :
  red (fst Σ) Γ t u -> Σ ;;; Γ |- v == u -> Σ ;;; Γ |- v == t.
Proof.
  intros. apply red_alt in X. apply clos_rt_rt1n_iff in X.
  induction X; auto.
  now econstructor 3; [eapply IHX|]; eauto.
Qed.

Lemma conv_alt_sym `{cf : checker_flags} (Σ : global_env_ext) Γ t u :
  wf Σ ->
  Σ ;;; Γ |- t == u -> Σ ;;; Γ |- u == t.
Proof.
  intros wfΣ X.
  induction X.
  - eapply eq_term_sym in e; now constructor.
  - eapply red_conv_conv_inv. eapply red1_red in r. eauto. eauto.
  - eapply red_conv_conv. eapply red1_red in r. eauto. eauto.
Qed.

Lemma conv_alt_red {cf : checker_flags} {Σ : global_env_ext} {Γ : context} {t u : term} :
  Σ;;; Γ |- t == u <~> (∑ v v' : term, (red Σ Γ t v × red Σ Γ u v') × eq_term (global_ext_constraints Σ) v v').
Proof.
  split. induction 1. exists t, u; intuition auto.
  destruct IHX as [? [? [? ?]]].
  exists x, x0; intuition auto. eapply red_step; eauto.
  destruct IHX as [? [? [? ?]]].
  exists x, x0; intuition auto. eapply red_step; eauto.
  intros.
  destruct X as [? [? [[? ?] ?]]].
  eapply red_conv_conv; eauto.
  eapply red_conv_conv_inv; eauto. now constructor.
Qed.

Lemma conv_alt_cumul `{cf : checker_flags} (Σ : global_env_ext) Γ t u : wf Σ ->
  Σ ;;; Γ |- t == u -> Σ ;;; Γ |- t <= u.
Proof.
  intros wfΣ H.
  apply conv_alt_red in H as [v [v' [[l r] eq]]].
  apply cumul_alt.
  exists v, v'; intuition auto. now eapply eq_term_leq_term.
Qed.

Lemma conv_alt_conv `{cf : checker_flags} (Σ : global_env_ext) Γ t u : wf Σ ->
  Σ ;;; Γ |- t == u -> Σ ;;; Γ |- t = u.
Proof.
  intros wfΣ H. split. now apply conv_alt_cumul.
  apply conv_alt_sym in H; auto. now apply conv_alt_cumul.
Qed.

Inductive conv_pb :=
| Conv
| Cumul.

Definition conv `{cf : checker_flags} leq Σ Γ u v :=
  match leq with
  | Conv => ∥ Σ ;;; Γ |- u == v ∥
  | Cumul => ∥ Σ ;;; Γ |- u <= v ∥
  end.

Lemma conv_conv_l `{cf : checker_flags} :
  forall (Σ : global_env_ext) leq Γ u v, wf Σ ->
      Σ ;;; Γ |- u == v ->
      conv leq Σ Γ u v.
Proof.
  intros Σ [] Γ u v h.
  - cbn. constructor. assumption.
  - cbn. constructor. now apply conv_alt_cumul.
Qed.

Lemma conv_conv_r `{cf : checker_flags} :
  forall (Σ : global_env_ext) leq Γ u v, wf Σ ->
      Σ ;;; Γ |- u == v ->
      conv leq Σ Γ v u.
Proof.
  intros Σ [] Γ u v wfΣ h.
  - cbn. constructor. apply conv_alt_sym; auto.
  - cbn. constructor. apply conv_alt_cumul. auto. now apply conv_alt_sym.
Qed.

Lemma cumul_App_l `{cf : checker_flags} :
  forall {Σ Γ f g x},
    Σ ;;; Γ |- f <= g ->
    Σ ;;; Γ |- tApp f x <= tApp g x.
Proof.
  intros Σ Γ f g x h.
  induction h.
  - eapply cumul_refl. constructor.
    + assumption.
    + apply eq_term_refl.
  - eapply cumul_red_l ; try eassumption.
    econstructor. assumption.
  - eapply cumul_red_r ; try eassumption.
    econstructor. assumption.
Qed.
