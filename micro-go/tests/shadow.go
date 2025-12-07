package main
import "fmt"

func main() {
    var x int = 1
    {
        var x int = 2
        fmt.Print(x)
    }
    fmt.Print(x)
}
