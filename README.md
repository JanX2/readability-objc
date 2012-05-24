#readability Objective-C

This is an Objective-C port of a python port of a ruby port of [arc90's readability project](http://lab.arc90.com/experiments/readability/). 

The goal is that given a URL, an HTML document or a Safari webarchive, it will pull out the main body text and clean it up.

Currently it deviates from the original in various ways: 

- Some implementation details were changed for performance reasons, others to speed up porting.
- It does not accept and produce HTML strings directly. 
	- main.m demonstrates how to use NSXMLDocument objects instead.
- There still are bugs in this port that are a result of porting.

readability-objc uses [KBWebArchiver](https://github.com/JanX2/webarchiver) to create a webarchive from the input if necessary. Amongst other things, this enables the automatic encoding detection implemented in WebKit.

KBWebArchiver is included as a submodule. After cloning a main repository, you initialize submodules by typing:

	git submodule init
	git submodule update

The code is licensed under the [Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0). 

##Based on:

- [buriy’s python-readability fork](https://github.com/buriy/python-readability).
- Github user contributions.

##Command-line usage demo:

    readability -url http://pypi.python.org/pypi/readability-lxml
