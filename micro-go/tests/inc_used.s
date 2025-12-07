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
  li   $t0, 1
  addi $sp, $sp, -4
  sw   $t0, 0($sp)
  lw   $t1, 0($sp)
  addi $sp, $sp, 4
  sw   $t1, -4($fp)
  lw   $t0, -4($fp)
  addi $t0, $t0, 1
  sw   $t0, -4($fp)
  addi $sp, $sp, 4
  move $sp, $fp
  lw   $fp, 0($sp)
  addi $sp, $sp, 4
  lw   $ra, 0($sp)
  addi $sp, $sp, 4
  jr   $ra
.data
