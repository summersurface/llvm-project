//===- VentusInstrFormatsV.td - Ventus V Instruction Formats -*- tablegen -*-=//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
//  This file describes the Ventus V extension instruction formats.
//
//===----------------------------------------------------------------------===//

class RISCVVFormat<bits<3> val> {
  bits<3> Value = val;
}
def OPIVV : RISCVVFormat<0b000>;
def OPFVV : RISCVVFormat<0b001>;
def OPMVV : RISCVVFormat<0b010>;
def OPIVI : RISCVVFormat<0b011>;
def OPIVX : RISCVVFormat<0b100>;
def OPFVF : RISCVVFormat<0b101>;
def OPMVX : RISCVVFormat<0b110>;
def OPCFG : RISCVVFormat<0b111>;

class RISCVMOP<bits<2> val> {
  bits<2> Value = val;
}
def MOPLDUnitStride   : RISCVMOP<0b00>;
def MOPSTUnitStride   : RISCVMOP<0b00>;

class RISCVLSUMOP<bits<5> val> {
  bits<5> Value = val;
}

def LUMOPUnitStride  : RISCVLSUMOP<0b00000>;
def LUMOPUnitStrideMask : RISCVLSUMOP<0b01011>;
def LUMOPUnitStrideWholeReg : RISCVLSUMOP<0b01000>;
def LUMOPUnitStrideFF: RISCVLSUMOP<0b10000>;
def SUMOPUnitStride  : RISCVLSUMOP<0b00000>;
def SUMOPUnitStrideMask : RISCVLSUMOP<0b01011>;
def SUMOPUnitStrideWholeReg : RISCVLSUMOP<0b01000>;

class RISCVWidth<bits<4> val> {
  bits<4> Value = val;
}
def LSWidth8     : RISCVWidth<0b0000>;
def LSWidth16    : RISCVWidth<0b0101>;
def LSWidth32    : RISCVWidth<0b0110>;
def LSWidth64    : RISCVWidth<0b0111>;

class RVInstSetVLi<dag outs, dag ins, string opcodestr, string argstr>
    : RVInst<outs, ins, opcodestr, argstr, [], InstFormatI> {
  bits<5> vs1;
  bits<5> rd;
  bits<11> vtypei;

  let Inst{31} = 0;
  let Inst{30-20} = vtypei;
  let Inst{19-15} = vs1;
  let Inst{14-12} = OPCFG.Value;
  let Inst{11-7} = rd;
  let Opcode = OPC_OP_V.Value;
}

// VENTUS VOP VI instructions with 11 bits immediate number
class PseudoVOPVIIMM11<SDPatternOperator Op> :
        Pseudo<(outs VGPR:$vd), (ins VGPR:$vs2, simm11:$imm11),
        [(set (XLenVT VGPR:$vd), (Op (XLenVT VGPR:$vs2), simm11:$imm11))]> {
  // let usesCustomInserter = 1;
  let hasSideEffects = 1;
  let mayLoad = 0;
  let mayStore = 0;
  let IsVOPIMM11 = 1;
}

class PseudoVOPIVIMM11<SDPatternOperator Op> :
        Pseudo<(outs VGPR:$vd), (ins VGPR:$vs2, simm11:$imm11),
        [(set (XLenVT VGPR:$vd), (Op simm11:$imm11, (XLenVT VGPR:$vs2)))]> {
  // let usesCustomInserter = 1;
  let hasSideEffects = 1;
  let mayLoad = 0;
  let mayStore = 0;
  let IsVOPIMM11 = 1;
}

class RVInstVV<bits<6> funct6, RISCVVFormat opv, dag outs, dag ins,
               string opcodestr, string argstr>
    : RVInst<outs, ins, opcodestr, argstr, [], InstFormatR> {
  bits<5> vs2;
  bits<5> vs1;
  bits<5> vd;

  let Inst{31-26} = funct6;
  let Inst{25} = 1;  // No mask on Ventus vALU, always encode vm bit to 1
  let Inst{24-20} = vs2;
  let Inst{19-15} = vs1;
  let Inst{14-12} = opv.Value;
  let Inst{11-7} = vd;
  let Opcode = OPC_OP_V.Value;
  let IsVVALUInstr = 1;

  let CustomConstraints = "$vd = 0,$vs1 = 1,$vs2 = 2";
}

// vALU branch
class RVInstVB<bits<3> funct3, dag outs, dag ins,
               string opcodestr, string argstr>
    : RVInst<outs, ins, opcodestr, argstr, [], InstFormatB> {
  bits<5> vs2;
  bits<5> vs1;
  bits<12> imm12;

  let Inst{31} = imm12{11};
  let Inst{30-25} = imm12{9-4};
  let Inst{24-20} = vs2;
  let Inst{19-15} = vs1;
  let Inst{14-12} = funct3;
  let Inst{11-8} = imm12{3-0};
  let Inst{7} = imm12{10};
  let Opcode = OPC_CUSTOM_2.Value;

  let CustomConstraints = "$vs1 = 1,$vs2 = 2";
}

class RVInstVX<bits<6> funct6, RISCVVFormat opv, dag outs, dag ins,
                string opcodestr, string argstr>
    : RVInst<outs, ins, opcodestr, argstr, [], InstFormatR> {
  bits<5> vs2;
  bits<5> rs1;
  bits<5> vd;

  let Inst{31-26} = funct6;
  let Inst{25} = 1;
  let Inst{24-20} = vs2;
  let Inst{19-15} = rs1;
  let Inst{14-12} = opv.Value;
  let Inst{11-7} = vd;
  let Opcode = OPC_OP_V.Value;

  let CustomConstraints = "$vd = 0,$rs1 = 1,$vs2 = 2";
}

class RVInstV2<bits<6> funct6, bits<5> vs2, RISCVVFormat opv, dag outs, dag ins,
                string opcodestr, string argstr>
    : RVInst<outs, ins, opcodestr, argstr, [], InstFormatR> {
  bits<5> rs1;
  bits<5> vd;

  let Inst{31-26} = funct6;
  let Inst{25} = 1;
  let Inst{24-20} = vs2;
  let Inst{19-15} = rs1;
  let Inst{14-12} = opv.Value;
  let Inst{11-7} = vd;
  let Opcode = OPC_OP_V.Value;

  let CustomConstraints = "$vd = 0,$rs1 = 1";
}

class RVInstIVI<bits<6> funct6, dag outs, dag ins, string opcodestr,
                string argstr>
    : RVInst<outs, ins, opcodestr, argstr, [], InstFormatR> {
  bits<5> vs2;
  bits<5> imm;
  bits<5> vd;

  let Inst{31-26} = funct6;
  let Inst{25} = 1;
  let Inst{24-20} = vs2;
  let Inst{19-15} = imm;
  let Inst{14-12} = OPIVI.Value;
  let Inst{11-7} = vd;
  let Opcode = OPC_OP_V.Value;

  let CustomConstraints = "$vd = 0,$vs2 = 2";
}

class RVInstV<bits<6> funct6, bits<5> vs1, RISCVVFormat opv, dag outs,
              dag ins, string opcodestr, string argstr>
    : RVInst<outs, ins, opcodestr, argstr, [], InstFormatR> {
  bits<5> vs2;
  bits<5> vd;

  let Inst{31-26} = funct6;
  let Inst{25} = 1;
  let Inst{24-20} = vs2;
  let Inst{19-15} = vs1;
  let Inst{14-12} = opv.Value;
  let Inst{11-7} = vd;
  let Opcode = OPC_OP_V.Value;

  let CustomConstraints = "$vd = 0,$vs2 = 2";
}

class RVInstVLX<bits<3> nf, bit mew, bits<3> width,
                dag outs, dag ins, string opcodestr, string argstr>
    : RVInst<outs, ins, opcodestr, argstr, [], InstFormatR> {
  bits<5> vs2;
  bits<5> rs1;
  bits<5> vd;

  let Inst{31-29} = nf;
  let Inst{28} = mew;
  let Inst{27-26} = 1; // mop[1:0]: Indexed-unordered
  let Inst{25} = 1;
  let Inst{24-20} = vs2;
  let Inst{19-15} = rs1;
  let Inst{14-12} = width;
  let Inst{11-7} = vd;
  let Opcode = OPC_LOAD_FP.Value;

  let CustomConstraints = "$vd = 0,$rs1 = 1,$vs2 = 2";
}

class RVInstVLU<bits<3> nf, bit mew, RISCVLSUMOP lumop,
                bits<3> width, dag outs, dag ins, string opcodestr,
                string argstr>
    : RVInst<outs, ins, opcodestr, argstr, [], InstFormatR> {
  bits<5> rs1;
  bits<5> vd;

  let Inst{31-29} = nf;
  let Inst{28} = mew;
  let Inst{27-26} = MOPLDUnitStride.Value;
  let Inst{25} = 1;
  let Inst{24-20} = lumop.Value;
  let Inst{19-15} = rs1;
  let Inst{14-12} = width;
  let Inst{11-7} = vd;
  let Opcode = OPC_LOAD_FP.Value;

  let CustomConstraints = "$vd = 0,$rs1 = 1";
}

class RVInstVSU<bits<3> nf, bit mew, RISCVLSUMOP sumop,
                bits<3> width, dag outs, dag ins, string opcodestr,
                string argstr>
    : RVInst<outs, ins, opcodestr, argstr, [], InstFormatR> {
  bits<5> rs1;
  bits<5> vs3;

  let Inst{31-29} = nf;
  let Inst{28} = mew;
  let Inst{27-26} = MOPSTUnitStride.Value;
  let Inst{25} = 1;
  let Inst{24-20} = sumop.Value;
  let Inst{19-15} = rs1;
  let Inst{14-12} = width;
  let Inst{11-7} = vs3;
  let Opcode = OPC_STORE_FP.Value;

  let CustomConstraints = "$vs3 = 0,$rs1 = 1";
}

class RVInstVSX<bits<3> nf, bit mew, bits<3> width,
                dag outs, dag ins, string opcodestr, string argstr>
    : RVInst<outs, ins, opcodestr, argstr, [], InstFormatR> {
  bits<5> vs2;
  bits<5> rs1;
  bits<5> vs3;

  let Inst{31-29} = nf;
  let Inst{28} = mew;
  let Inst{27-26} = 1; // mop[1:0]: Index-unordered
  let Inst{25} = 1;
  let Inst{24-20} = vs2;
  let Inst{19-15} = rs1;
  let Inst{14-12} = width;
  let Inst{11-7} = vs3;
  let Opcode = OPC_STORE_FP.Value;

  let CustomConstraints = "$vs3 = 0,$rs1 = 1,$vs2 = 2";
}
