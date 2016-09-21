# Browsing Paddle C++ Source Code

By git-cloning this repository and running `vagrant up`, we use
[woboq_codebrowser](https://github.com/woboq/woboq_codebrowser) to
convert [Paddle](https://github.com/baidu/paddle) into indexed and
browsable HTML files in `paddle_html` directory.  We can then copy the
directory to a Web server so to publish the result, for example,
[here](https://link.zhihu.com/?target=http%3A//162.243.141.242/paddle_html/codebrowser/codebrowser/paddle/trainer/TrainerMain.cpp.html)

For more details like why we would like to browse Paddle source code,
please refer to
[this post](https://zhuanlan.zhihu.com/p/22484207?refer=cxwangyi) in
Chinese.

TODO: It seems that we don't have to do this as provisioning a virtual
machine; instead, we can do it as building a Docker image.

<!--  LocalWords:  woboq codebrowser html
 -->
