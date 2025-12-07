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
  li   $t0, 40
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  li   $t0, 2
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  sub  $t0, $t1, $t0
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  li   $t0, 3
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  li   $t0, 1
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  add  $t0, $t1, $t0
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  li   $t0, 4
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  mul  $t0, $t1, $t0
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  li   $t0, 8
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  div  $t0, $t1, $t0
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  sub  $t0, $t1, $t0
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  li   $t0, 6
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  add  $t0, $t1, $t0
  move $a0, $t0
  li   $v0, 1
  syscall
  move $sp, $fp
  lw   $fp, 0($sp)
  addi $sp, $sp, 4
  lw   $ra, 0($sp)
  addi $sp, $sp, 4
  jr   $ra
.data
