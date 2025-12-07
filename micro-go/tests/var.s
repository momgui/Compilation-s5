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
  addi $sp, $sp, -8
  li   $t0, 1
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  sw   $t1, -4($fp)
  li   $t0, 6
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  sw   $t1, -8($fp)
  lw   $t0, -4($fp)
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  li   $t0, 2
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  add  $t0, $t1, $t0
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  sw   $t1, -4($fp)
  lw   $t0, -8($fp)
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  lw   $t0, -4($fp)
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  li   $t0, 4
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  add  $t0, $t1, $t0
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  mul  $t0, $t1, $t0
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  sw   $t1, -8($fp)
  lw   $t0, -8($fp)
  move $a0, $t0
  li   $v0, 1
  syscall
  addi $sp, $sp, 8
  move $sp, $fp
  lw   $fp, 0($sp)
  addi $sp, $sp, 4
  lw   $ra, 0($sp)
  addi $sp, $sp, 4
  jr   $ra
.data
