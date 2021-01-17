# Lab 0

## Screencast:

[Download screencast.mp4](https://github.com/rogvc/cs462/blob/master/lab0/resources/screencast.mp4?raw=true)

## 1. What is the public URL of your hello_world ruleset?
[hello_world.krl](https://raw.githubusercontent.com/rogvc/cs462/master/lab0/rulesets/hello_world.krl)

## 2. What happened when you parsed the improperly formatted ruleset? What error did you see?
I couldn't commit because I installed a pre-commit hook.  
Also, when I ran the `krl-compiler --verify` command, I got an error saying: `ParseError: Expected  '}' [at line 23 col 3]`

![The error](https://github.com/rogvc/cs462/blob/master/lab0/resources/parse-error.png?raw=true)

## 3. What port was your pico engine running on?
Pico was running on `http://localhost:3000`
