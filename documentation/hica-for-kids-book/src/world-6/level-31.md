# Level 31. Under the Hood: The Translator

This is the coolest part of hica. When you run your program, three things
happen behind the scenes:

```
Your code (.hc)  →  Koka (.kk)  →  C  →  Your computer runs it!
```

| Layer | What it is |
| --- | --- |
| **hica** (`.hc`) | The "Human Language" — easy for you to read and write |
| **Koka** (`.kk`) | The "Translator" — converts your code into something lower-level |
| **C** | The "Robot Language" — super fast, used to build operating systems |

So when you write `fun double(n) => n * 2`, your simple one-liner becomes
serious, optimised C code. You get the **easy** writing experience and the
**fast** running speed.

### Perceus: The Memory Cleaner

When your program creates values (boxes), it uses memory. Some languages need a
"garbage collector" that pauses your program to clean up, like stopping a race
car to pick up litter. hica uses **Perceus** instead: it counts exactly how
many times each box is used and cleans it up the instant nobody needs it
anymore. No pauses, no slowdowns.

