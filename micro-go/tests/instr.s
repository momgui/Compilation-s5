.text
  jal  main
  li   $v0, 10
  syscall
main:
  addi $sp, $sp, -4
  sw   $ra, 0($sp)
  addi $sp, $sp, -4
  sw   $fp, 0($sp)
  move $fp, $sp
  addi $sp, $sp, -12
  li   $t0, 2
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  sw   $t1, -4($fp)
  li   $t0, 9
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  sw   $t1, -8($fp)
  li   $t0, 1
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  sw   $t1, -12($fp)
  b    _label_0
_label_1:
  lw   $t0, -8($fp)
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  li   $t0, 2
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  rem  $t0, $t1, $t0
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  li   $t0, 0
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  sne  $t0, $t1, $t0
  bnez $t0, _label_2
  b    _label_3
_label_2:
  lw   $t0, -4($fp)
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  lw   $t0, -12($fp)
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  mul  $t0, $t1, $t0
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  sw   $t1, -12($fp)
_label_3:
  lw   $t0, -4($fp)
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  lw   $t0, -4($fp)
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  mul  $t0, $t1, $t0
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  sw   $t1, -4($fp)
  lw   $t0, -8($fp)
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  li   $t0, 2
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  div  $t0, $t1, $t0
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  sw   $t1, -8($fp)
_label_0:
  lw   $t0, -8($fp)
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  li   $t0, 0
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  sne  $t0, $t1, $t0
  bnez $t0, _label_1
  lw   $t0, -12($fp)
  move $a0, $t0
  li   $v0, 1
  syscall
  addi $sp, $sp, 12
  move $sp, $fp
  lw   $fp, 0($sp)
  addi $sp, $sp, 4
  lw   $ra, 0($sp)
  addi $sp, $sp, 4
  jr   $ra
.data
