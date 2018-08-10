# UIViewControllerLoadResultHint

#### 项目介绍

当某个UIViewController页面显示后，无相应内容时展示给用户的提示
类似于https://github.com/dzenbot/DZNLoadResultHint

```

self.loadResultDataSource = self;
self.loadResultDelegate = self;

...根据需求实现代理方法

//show:
[self showAndReloadLoadResultHint];

//hide:
[self hideLoadResultHint];

```

#### 安装教程

pod 'UIViewControllerLoadResultHint'

#### 示例

![example](https://github.com/safiriGitHub/UIViewControllerLoadResultHint/blob/master/example3.gif)

