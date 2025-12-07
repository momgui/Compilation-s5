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
  li   $a0, 8
  li   $v0, 9
  syscall
  move $t0, $v0
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  sw   $t1, -4($fp)
  li   $a0, 8
  li   $v0, 9
  syscall
  move $t0, $v0
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
  addi $sp, $sp, -4
  sw   $t1, 0($sp)
  lw   $t0, -4($fp)
  lw   $t2, 0($sp)
  addi $sp, $sp, 4
  sw   $t2, 0($t0)
  li   $t0, 2
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  addi $sp, $sp, -4
  sw   $t1, 0($sp)
  lw   $t0, -4($fp)
  lw   $t2, 0($sp)
  addi $sp, $sp, 4
  sw   $t2, 4($t0)
  li   $t0, 3
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  addi $sp, $sp, -4
  sw   $t1, 0($sp)
  lw   $t0, -8($fp)
  lw   $t2, 0($sp)
  addi $sp, $sp, 4
  sw   $t2, 0($t0)
  li   $t0, 4
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  addi $sp, $sp, -4
  sw   $t1, 0($sp)
  lw   $t0, -8($fp)
  lw   $t2, 0($sp)
  addi $sp, $sp, 4
  sw   $t2, 4($t0)
  lw   $t0, -4($fp)
  lw   $t0, 0($t0)
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  lw   $t0, -4($fp)
  lw   $t0, 4($t0)
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  add  $t0, $t1, $t0
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  lw   $t0, -8($fp)
  lw   $t0, 0($t0)
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  add  $t0, $t1, $t0
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  lw   $t0, -8($fp)
  lw   $t0, 4($t0)
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  add  $t0, $t1, $t0
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
