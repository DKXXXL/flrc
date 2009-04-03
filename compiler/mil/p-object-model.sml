(* The Intel P to C/Pillar Compiler *)
(* Copyright (C) Intel Corporation *)

(* This module defines how P concepts are modelled in Mil *)

signature P_OBJECT_MODEL = 
sig

  structure Double : sig
    val td : Mil.tupleDescriptor
    val typ : Mil.typ
    val mk : Config.t * Mil.operand -> Mil.rhs
    val mkGlobal : Config.t * Real64.t -> Mil.global
    val ofValIndex : int
    val extract : Config.t * Mil.variable -> Mil.rhs
  end

  structure Float : sig
    val td : Mil.tupleDescriptor
    val typ : Mil.typ
    val mk : Config.t * Mil.operand -> Mil.rhs
    val mkGlobal : Config.t * Real32.t -> Mil.global
    val ofValIndex : int
    val extract : Config.t * Mil.variable -> Mil.rhs
  end

  structure Function  : sig
    val td : Config.t * Mil.fieldKind Vector.t -> Mil.tupleDescriptor
    val closureTyp : Mil.typ Vector.t * Mil.typ Vector.t -> Mil.typ
    val codeTyp : Mil.typ * Mil.typ Vector.t * Mil.typ Vector.t -> Mil.typ
    val codeIndex : int
    val fvIndex : int -> int
    val mkUninit : Config.t * Mil.fieldKind Vector.t -> Mil.rhs
    val mkInit : Config.t
                 * Mil.operand
                 * (Mil.fieldKind * Mil.operand) Vector.t
                 -> Mil.rhs
    val mkGlobal : Config.t * Mil.operand -> Mil.global
    val init : Config.t
               * Mil.variable
               * Mil.operand
               * (Mil.fieldKind * Mil.operand) Vector.t
               -> Mil.rhs list
    val getCode : Config.t * Mil.variable -> Mil.rhs
    val getFv : Config.t * Mil.fieldKind Vector.t * Mil.variable * int
                -> Mil.rhs
    val doCall : Config.t
                 * Mil.variable         (* code *)
                 * Mil.variable         (* closure *)
                 * Mil.operand Vector.t (* args *)
                 -> Mil.call * Mil.operand Vector.t
  end

  structure IndexedArray : sig
    val tdVar : Config.t * Mil.fieldKind -> Mil.tupleDescriptor
    val fixedTyp : Config.t * int Identifier.NameDict.t * Mil.typ Vector.t
                   -> Mil.typ
    val varTyp : Config.t * Mil.typ -> Mil.typ
    val lenIndex : int
    val idxIndex : int
    val newFixed : Config.t
                   * int Identifier.NameDict.t
                   * Mil.fieldKind Vector.t
                   * Mil.variable
                   * Mil.operand Vector.t
                   -> Mil.rhs
    val idxSub : Config.t * Mil.fieldKind * Mil.variable * Mil.operand
                 -> Mil.rhs
  end

  structure OrdinalArray : sig
    val tdVar : Config.t * Mil.fieldKind -> Mil.tupleDescriptor
    val fixedTyp : Config.t * Mil.typ Vector.t -> Mil.typ
    val varTyp : Config.t * Mil.typ -> Mil.typ
    val lenIndex : int
    val newFixed : Config.t * Mil.fieldKind Vector.t * Mil.operand Vector.t
                   -> Mil.rhs
    val newVar : Config.t * Mil.fieldKind * Mil.operand -> Mil.rhs
    val length : Config.t * Mil.variable -> Mil.rhs
    val sub : Config.t * Mil.fieldKind * Mil.variable * Mil.operand -> Mil.rhs
    val update : Config.t * Mil.fieldKind * Mil.variable * Mil.operand
                 * Mil.operand
                 -> Mil.rhs
    val inited : Config.t * Mil.fieldKind * Mil.variable -> Mil.rhs
  end

  structure OptionSet : sig
    val td : Config.t -> Mil.tupleDescriptor
    val loweredTyp : Mil.typ -> Mil.typ
    val empty : Config.t -> Mil.rhs
    val emptyGlobal : Config.t -> Mil.global
    val mk : Config.t * Mil.operand -> Mil.rhs
    val mkGlobal : Config.t * Mil.simple -> Mil.global
    val ofValIndex : int
    val get : Config.t * Mil.variable -> Mil.rhs
    val query : Config.t * Mil.variable -> Mil.rhs * Mil.typ * Mil.constant
  end

  structure Rat : sig
    val td : Mil.tupleDescriptor
    val typ : Mil.typ
    val mk : Config.t * Mil.operand -> Mil.rhs
    val mkGlobal : Config.t * Mil.simple -> Mil.global
    val ofValIndex : int
    val extract : Config.t * Mil.variable -> Mil.rhs
  end

  structure Ref : sig
    val loweredTyp : Mil.typ -> Mil.typ
  end

  structure Sum : sig
    val td : Config.t * Mil.fieldKind -> Mil.tupleDescriptor
    val loweredTyp : Mil.typ Identifier.NameDict.t -> Mil.typ
    val mk : Config.t * Mil.name * Mil.fieldKind * Mil.operand -> Mil.rhs
    val mkGlobal : Config.t * Mil.name * Mil.fieldKind * Mil.simple
                   -> Mil.global
    val tagIndex : int
    val ofValIndex : int
    val getTag : Config.t * Mil.variable * Mil.fieldKind -> Mil.rhs
    val getVal : Config.t * Mil.variable * Mil.fieldKind -> Mil.rhs
  end

  structure Type : sig
    val td : Mil.tupleDescriptor
    val loweredTyp : Mil.typ -> Mil.typ
    val placeHolder : Mil.rhs
    val placeHolderGlobal : Mil.global
  end

end;

structure PObjectModel :> P_OBJECT_MODEL = 
struct

  structure M = Mil
  structure MU = MilUtils
  structure B = MU.Boxed
  structure OA = MU.OrdinalArray
  structure IA = MU.IndexedArray

  structure Double =
  struct

    val td = B.td (M.FkBits M.Fs64)

    val typ = B.t (M.PokDouble, M.TDouble)

    fun mk (c, opnd) = B.box (c, M.PokDouble, M.FkBits M.Fs64, opnd)

    fun mkGlobal (c, d) =
        B.boxGlobal (c, M.PokDouble, M.FkBits M.Fs64,
                     M.SConstant (M.CDouble d))

    val ofValIndex = B.ofValIndex

    fun extract (c, v) = B.unbox (c, M.FkBits M.Fs64, v)

  end

  structure Float =
  struct

    val td = B.td (M.FkBits M.Fs32)

    val typ = B.t (M.PokFloat, M.TFloat)

    fun mk (c, opnd) = B.box (c, M.PokFloat, M.FkBits M.Fs32, opnd)

    fun mkGlobal (c, f) =
        B.boxGlobal (c, M.PokFloat, M.FkBits M.Fs32, M.SConstant (M.CFloat f))

    val ofValIndex = B.ofValIndex

    fun extract (c, v) = B.unbox (c, M.FkBits M.Fs32, v)

  end

  structure Function  =
  struct

    fun codeTyp (cls, args, ress) =
        M.TCode {cc = M.CcCode, args = Utils.vcons (cls, args), ress = ress}

    fun closureTyp (args, ress) =
        let
          (* The code's first argument is the closure itself.
           * To express this properly would require a recursive
           * type.  Instead we approximate with TRef.
           *)
          val ct = codeTyp (M.TRef, args, ress)
          val fts = Vector.new1 (ct, M.FvReadOnly)
        in
          M.TTuple {pok = M.PokFunction, fixed = fts, array = NONE}
        end


    val codeIndex = 0
    fun fvIndex i = i + 1

    fun td (c, fks) =
      let
        val fks = Utils.vcons (MU.FieldKind.nonRefPtr c, fks)
        fun doOne fk = M.FD {kind = fk, var = M.FvReadOnly}
        val fds = Vector.map (fks, doOne)
        val td = M.TD {fixed = fds, array = NONE}
      in td
      end

    fun vtd (c, fks) =
      let
        val pok = M.PokFunction
        val fks = Utils.vcons (MU.FieldKind.nonRefPtr c, fks)
        fun doOne fk = M.FD {kind = fk, var = M.FvReadOnly}
        val fds = Vector.map (fks, doOne)
        val vtd = M.VTD {pok = pok, fixed = fds, array = NONE}
      in vtd
      end

    fun mkUninit (c, fks) =
        M.RhsTuple {vtDesc = vtd (c, fks), inits = Vector.new0 ()}

    fun mkInit (c, code, fkos) =
        let
          val (fks, os) = Vector.unzip fkos
        in
          M.RhsTuple {vtDesc = vtd (c, fks), inits = Utils.vcons (code, os)}
        end

    fun mkGlobal (c, code) =
        M.GTuple {vtDesc = vtd (c, Vector.new0 ()), inits = Vector.new1 code}

    fun init (c, cls, code, fkos) =
        let
          val (fks, os) = Vector.unzip fkos
          val td = td (c, fks)
          val codetf =
              M.TF {tupDesc = td, tup = cls, field = M.FiFixed codeIndex}
          val coderhs = M.RhsTupleSet {tupField = codetf, ofVal = code}
          fun doOne (i, opnd) =
              let
                val f = M.FiFixed (fvIndex i)
                val tf = M.TF {tupDesc = td, tup = cls, field = f}
                val rhs = M.RhsTupleSet {tupField = tf, ofVal = opnd}
              in rhs
              end
          val fvsrhs = List.mapi (Vector.toList os, doOne)
        in coderhs::fvsrhs
        end

    fun getCode (c, cls) =
        let
          val td = td (c, Vector.new0 ())
          val f = M.FiFixed codeIndex
          val rhs = M.RhsTupleSub (M.TF {tupDesc = td, tup = cls, field = f})
        in rhs
        end

    fun getFv (c, fks, cls, idx) =
        let
          val td = td (c, fks)
          val f = M.FiFixed (fvIndex idx)
          val rhs = M.RhsTupleSub (M.TF {tupDesc = td, tup = cls, field = f})
        in rhs
        end

    fun doCall (c, codev, clsv, args) =
        (M.CCode codev, Utils.vcons (M.SVariable clsv, args))
        
  end

  structure IndexedArray =
  struct

    fun tdVar (c, fk) = IA.tdVar (c, fk)

    fun fixedTyp (c, d, ts) = IA.fixedTyp (c, M.PokIArray, d, ts)

    fun varTyp (c, t) = IA.varTyp (c, M.PokIArray, t)

    val lenIndex = IA.lenIndex
    val idxIndex = IA.idxIndex

    fun newFixed (c, d, fks, v, os) =
        IA.newFixed (c, M.PokIArray, d, fks, v, os)

    fun idxSub (c, fk, v, opnd) = IA.idxSub (c, fk, v, opnd)

  end

  structure OrdinalArray =
  struct

    fun tdVar (c, fk) = OA.tdVar (c, fk)

    fun fixedTyp (c, ts) = OA.fixedTyp (c, M.PokOArray, ts)

    fun varTyp (c, t) = OA.varTyp (c, M.PokOArray, t)

    val lenIndex = OA.lenIndex

    fun newFixed (c, fks, os) = OA.newFixed (c, M.PokOArray, fks, os)

    fun newVar (c, fk, opnd) = OA.newVar (c, M.PokOArray, fk, opnd)

    fun length (c, v) = OA.length (c, v)

    fun sub (c, fk, v, opnd) = OA.sub (c, fk, v, opnd)

    fun update (c, fk, v, o1, o2) = OA.update (c, fk, v, o1, o2)

    fun inited (c, fk, v) = OA.inited (c, M.PokOArray, fk, v)

  end

  structure OptionSet =
  struct

    fun loweredTyp t =
        M.TTuple {pok = M.PokOptionSet,
                  fixed = Vector.new1 (t, M.FvReadOnly),
                  array = NONE}

    val ofValIndex = B.ofValIndex

    fun nulConst c = MU.UIntp.zero c

    fun empty c =
        let
          val pok = M.PokOptionSet
          val fd = M.FD {kind = M.FkRef, var = M.FvReadOnly}
          val vtd = M.VTD {pok = pok, fixed = Vector.new1 fd, array = NONE}
          val zero = M.SConstant (nulConst c)
        in M.RhsTuple {vtDesc = vtd, inits = Vector.new1 zero}
        end

    fun emptyGlobal c =
        let
          val pok = M.PokOptionSet
          val fd = M.FD {kind = M.FkRef, var = M.FvReadOnly}
          val vtd = M.VTD {pok = pok, fixed = Vector.new1 fd, array = NONE}
          val zero = M.SConstant (nulConst c)
        in M.GTuple {vtDesc = vtd, inits = Vector.new1 zero}
        end

    fun td c =
        let
          val fixed = Vector.new1 (M.FD {kind = M.FkRef, var = M.FvReadOnly})
          val td = M.TD {fixed = fixed, array = NONE}
        in td
        end

    fun vtd c =
        let
          val pok = M.PokOptionSet
          val fixed = Vector.new1 (M.FD {kind = M.FkRef, var = M.FvReadOnly})
          val vtd = M.VTD {pok = pok, fixed = fixed, array = NONE}
        in vtd
        end

    fun mk (c, opnd) =
        let
          val vtd = vtd c
          val rhs = M.RhsTuple {vtDesc = vtd, inits = Vector.new1 opnd}
        in rhs
        end

    fun mkGlobal (c, s) =
        let
          val vtd = vtd c
          val g = M.GTuple {vtDesc = vtd, inits = Vector.new1 s}
        in g
        end

    val ofValIndex = 0

    fun get (c, v) =
        let
          val td = td c
          val f = M.FiFixed ofValIndex
          val rhs = M.RhsTupleSub (M.TF {tupDesc = td, tup = v, field = f})
        in rhs
        end

    fun query (c, v) =
        (get (c, v), M.TRef, nulConst c)

  end

  structure Rat =
  struct

    val td = B.td M.FkRef

    val typ = B.t (M.PokRat, M.TRat)

    fun mk (c, opnd) = B.box (c, M.PokRat, M.FkRef, opnd)

    fun mkGlobal (c, s) = B.boxGlobal (c, M.PokRat, M.FkRef, s)

    val ofValIndex = B.ofValIndex

    fun extract (c, v) = B.unbox (c, M.FkRef, v)

  end

  structure Ref =
  struct

    fun loweredTyp t =
        Fail.unimplemented ("PObjectModel.Ref", "loweredTyp", "*")

  end

  structure Sum =
  struct

    fun loweredTyp nts =
        M.TTuple {pok = M.PokSum,
                  fixed = Vector.new1 (M.TName, M.FvReadOnly),
                  array = NONE}

    fun td (c, fk) =
        let
          val fds = Vector.new2 (M.FD {kind = M.FkRef, var = M.FvReadOnly},
                                 M.FD {kind = fk,      var = M.FvReadOnly})
          val td = M.TD {fixed = fds, array = NONE}
        in td
        end

    fun vtd (c, fk) =
        let
          val fds = Vector.new2 (M.FD {kind = M.FkRef, var = M.FvReadOnly},
                                 M.FD {kind = fk,      var = M.FvReadOnly})
          val vtd = M.VTD {pok = M.PokSum, fixed = fds, array = NONE}
        in vtd
        end

    fun mk (c, tag, fk, ofVal) =
        let
          val vtd = vtd (c, fk)
          val inits = Vector.new2 (M.SConstant (M.CName tag), ofVal)
          val rhs = M.RhsTuple {vtDesc = vtd, inits = inits}
        in rhs
        end

    fun mkGlobal (c, tag, fk, ofVal) =
        let
          val vtd = vtd (c, fk)
          val inits = Vector.new2 (M.SConstant (M.CName tag), ofVal)
          val g = M.GTuple {vtDesc = vtd, inits = inits}
        in g
        end

    val tagIndex = 0
    val ofValIndex = 1

    fun getTag (c, v, fk) =
        let
          val td = td (c, fk)
          val f = M.FiFixed tagIndex
          val rhs = M.RhsTupleSub (M.TF {tupDesc = td, tup = v, field = f})
        in rhs
        end

    fun getVal (c, v, fk) =
        let
          val td = td (c, fk)
          val f = M.FiFixed ofValIndex
          val rhs = M.RhsTupleSub (M.TF {tupDesc = td, tup = v, field = f})
        in rhs
        end

  end

  structure Type =
  struct

    fun loweredTyp t =
        M.TTuple {pok = M.PokType, fixed = Vector.new0 (), array = NONE}

    val td = M.TD {fixed = Vector.new0 (), array = NONE}

    val vtd = M.VTD {pok = M.PokType, fixed = Vector.new0 (), array = NONE}

    val placeHolder = M.RhsTuple {vtDesc = vtd, inits = Vector.new0 ()}
                    
    val placeHolderGlobal = M.GTuple {vtDesc = vtd, inits = Vector.new0 ()}
                    
  end

end;
