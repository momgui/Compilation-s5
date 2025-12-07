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
  addi $sp, $sp, -4
  li   $t0, 0
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  sw   $t1, -4($fp)
  lw   $t0, -4($fp)
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  li   $t0, 0
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  seq  $t0, $t1, $t0
  bnez $t0, _label_0
  b    _label_1
_label_0:
  la   $t0, _label_2
  move $a0, $t0
  li   $v0, 4
  syscall
_label_1:
  li   $t0, 0
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  lw   $t0, -4($fp)
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  seq  $t0, $t1, $t0
  bnez $t0, _label_3
  b    _label_4
_label_3:
  la   $t0, _label_2
  move $a0, $t0
  li   $v0, 4
  syscall
_label_4:
  addi $sp, $sp, 4
  move $sp, $fp
  lw   $fp, 0($sp)
  addi $sp, $sp, 4
  lw   $ra, 0($sp)
  addi $sp, $sp, 4
  jr   $ra
.data
_label_2:
  .asciiz "ok"
