package main
import "fmt"

type S struct { x int }

func main() {
    var p *S = nil
    if p == nil {
        fmt.Print("ok")
    }
    if nil == p {
        fmt.Print("ok")
    }
}
