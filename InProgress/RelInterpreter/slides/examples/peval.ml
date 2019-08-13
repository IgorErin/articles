open MiniKanrenStd
open MiniKanren
open GT

module Simple =
  struct
   
    @type ('a, 'b) fa =
    | Conj of 'a * 'a
    | Disj of 'a * 'a
    | Var  of 'b with show, gmap

    @type f = (f, string logic) fa logic with show, gmap

    module F = Fmap2 (struct type ('a, 'b) t = ('a, 'b) fa let fmap f g x = gmap(fa) f g x end)

    let rec reify_f f = F.reify reify_f reify f
                  
    let conj x y = inj @@ F.distrib (Conj (x, y))
    let disj x y = inj @@ F.distrib (Disj (x, y))
    let var  x   = inj @@ F.distrib (Var x)

    let rec evalo st fm =
      fresh (x y v) (
        conde [
          fm === conj x y &&& evalo st x &&& evalo st y;
          fm === disj x y &&& (evalo st x ||| evalo st y);
          fm === var  v   &&& List.membero st v
      ])

    let _ =
      Printf.printf "%d\n" @@
      List.length @@ Stream.take @@
      run qrs
        (fun q r s -> (List.lengtho s (nat 2)) &&& (r =/= q) &&& evalo s (disj (var r) (var q)))
        (fun q r s -> s);
  
      List.iter (fun s -> Printf.printf "%s\n" @@ show(f) (s#reify reify_f)) @@ Stream.take ~n:10 @@
      run qrs
        (fun q r s -> (r =/= q) &&& evalo (r %< q) s)
        (fun _ _ s -> s)
      
  end
    
module Elaborated =
  struct
   
    @type ('a, 'b) fa =
    | Conj of 'a * 'a
    | Disj of 'a * 'a
    | Neg  of 'a
    | Var  of 'b with show, gmap

    @type f = (f, string logic) fa logic with show, gmap

    module F = Fmap2 (struct type ('a, 'b) t = ('a, 'b) fa let fmap f g x = gmap(fa) f g x end)

    let rec reify_f f = F.reify reify_f reify f
                  
    let conj x y = inj @@ F.distrib (Conj (x, y))
    let disj x y = inj @@ F.distrib (Disj (x, y))
    let var  x   = inj @@ F.distrib (Var x)
    let neg  x   = inj @@ F.distrib (Neg x)

    let rec eval st = function
    | Conj (l, r) -> eval st l && eval st r
    | Disj (l, r) -> eval st l || eval st r
    | Neg   e     -> not (eval st e)
    | Var   x     -> List.assoc x st
                   
    let rec evalo st fm u =
      fresh (x y z v w) (
        conde [
          ?& [fm === conj x y; evalo st x v; evalo st y w; Bool.ando v w u];
          ?& [fm === disj x y; evalo st x v; evalo st y w; Bool.oro  v w u];
          ?& [fm === neg  x  ; evalo st x v; Bool.noto v u];
          ?& [fm === var  z  ; List.assoco z st u];
        ])

    let _ =
      Printf.printf "*********************************\n";
      List.iter (fun s ->
          Printf.printf "%s\n" @@ show(List.logic)
                                    (show(Pair.logic)
                                       (show(logic) (show(string)))
                                       (show(logic) (show(bool)))
                                    )
                                  
                                    (s#reify (List.reify (Pair.reify reify reify)))) @@ Stream.take ~n:10 @@
      run q
        (fun st -> evalo st (conj (neg @@ var !!"x") (var !!"y")) !!true)
        (fun st -> st)
  
  end
    
    
         

                                                  