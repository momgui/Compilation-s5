package main
import "fmt"

type Node struct {
    val int
    next *Node
}

func swap(x, y int) (int, int) {
    return y, x
}

func main() {
    // Multiple return
    var a, b int = 1, 2
    a, b = swap(a, b)
    if a != 2 || b != 1 { fmt.Print("Swap failed") }

    // Recursive struct
    var n1 *Node = new(Node)
    n1.val = 10
    var n2 *Node = new(Node)
    n2.val = 20
    n1.next = n2
    
    if n1.next.val != 20 { fmt.Print("Struct link failed") }

    // Nil check
    if n1.next == nil { fmt.Print("Should not be nil") }
    n1.next = nil
    if n1.next != nil { fmt.Print("Should be nil") }

    // For loops
    var i int = 0
    for i < 5 {
        i++
    }
    if i != 5 { fmt.Print("For loop failed") }

    for i = 0; i < 5; i++ {
    }
    
    // Complex expressions
    if (1 + 2) * 3 != 9 { fmt.Print("Math failed") }
    if !true || false { fmt.Print("Logic failed") }
}
