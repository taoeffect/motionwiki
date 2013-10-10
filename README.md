# MotionWiki

A browser bookmarklet and extension for bringing the history of a Wikipedia page to life.

<!-- 
Regex to create anchors for headings:
 Search: ^([#]{2,}+) (\S+)(.*)
Replace: $1 $2$3<a name="$2"/>

Regex for TOC links IN SELECTION:
 Search: ^(\s*)- (\S+)(.*)
Replace: $1- [$2$3](#$2)
-->
- [Installation](#Instructions)
- [Running the demo](#Running)
- [A *Team Wiki Wizards* Production](#A)
- [MIT License](#MIT)

## Installation Instructions<a name="Instructions"/>

MotionWiki requires the following developers tools:

- [npm](https://npmjs.org/) (Installed by installed `node`)
- [bower](http://bower.io/)
- [grunt](http://gruntjs.com/)

#### Mac OS X<a name="Mac"/>

Install [homebrew](http://brew.sh/). Follow the advice given via the `brew doctor` command. Then run:

    brew install node

*(NOTE: We recommend installing `git` via `brew` too!)*

#### Linux<a name="Linux"/>

[These are the latest instructions](https://github.com/joyent/node/wiki/Installing-Node.js-via-package-manager) for installing nodejs (and thereby `npm`) as of October 10th, 2013. They might get outdated in the future, so use your amazing Internet search abilities if they don't work!

#### Windows<a name="Windows"/>

Install [Linux Mint](http://www.linuxmint.com/) (the Ubuntu-based one) on your computer. You can either replace Windows (**recommended**), or dual-boot, or run Linux in a virtual machine. 

MotionWiki will not compile on Windows because of `requirejs` bugs related to backslashes on Windows.

### Install grunt and bower<a name="Install"/>

In a Terminal, run:

    [prompt]$ npm install -g grunt-cli
    [prompt]$ npm install -g bower

## Running the demo<a name="Running"/>

`cd` into the project directory:

    [prompt]$ cd path/to/motionwiki
    [prompt]$ npm install
    [prompt]$ grunt bowerful dev

Then visit: [http://127.0.0.1:8080](http://127.0.0.1:8080)

From then on you can simple run `grunt`, which is an alias for `grunt dev`.

## A *Team Wiki Wizards* Production<a name="A"/>

MotionWiki was created as part of a group project at the University of Florida for a Software Engineering class. It is the brainchild of [Greg Slepak](https://github.com/taoeffect) and is the result of the combined effort of *Team Wiki Wizards*:

- [@taoeffect](https://github.com/taoeffect)
- [@jwonesh](https://github.com/jwonesh)
- [@jordanfine](https://github.com/jordanfine)
- [@jlucka625](https://github.com/jlucka625)
- [@MatthewJohnson3154](https://github.com/MatthewJohnson3154)
- [@nwcaldwell](https://github.com/nwcaldwell)
- [@Spyrix](https://github.com/Spyrix)
- [@samlin811](https://github.com/samlin811)
- [@tsingh777](https://github.com/tsingh777)

## MIT License<a name="MIT"/>

    The MIT License (MIT)
    
    Copyright (c) 2013 Team Wiki Wizards
    
    Permission is hereby granted, free of charge, to any person obtaining a copy of
    this software and associated documentation files (the "Software"), to deal in
    the Software without restriction, including without limitation the rights to
    use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
    the Software, and to permit persons to whom the Software is furnished to do so,
    subject to the following conditions:
    
    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.
    
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
    FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
    COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
    IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
    CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
