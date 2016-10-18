# Paddle 的 Data Provider

Yi Wang


## 概述

一个 Paddle 程序通常包括两个部分：data provider 和 主程序。


在 Paddle 的 [Quick Start tutorial](http://www.paddlepaddle.org/doc/demo/quick_start/index_en.html) 里，一个很简答主程序是 [trainer_config.lr.py](https://github.com/baidu/Paddle/blob/master/demo/quick_start/trainer_config.lr.py)，其中[调用](https://github.com/baidu/Paddle/blob/master/demo/quick_start/trainer_config.lr.py#L35)函数 `define_py_data_source2` 指定了它的 data provider：

```
define_py_data_sources2(train_list=trn,
                        test_list=tst,
                        module="dataprovider_bow",
                        obj=process,
                        args={"dictionary": word_dict})
```

这个调用指定了训练数据 `trn = 'data/train.list'` 和测试数据 `tst = 'data/test.list'`。这是两个文本文件，其中每行是一个数据文件的名字。读取数据文件的 Python 函数是 [`process`](https://github.com/baidu/Paddle/blob/master/demo/quick_start/dataprovider_bow.py#L50)，它被定义在 `dataprovider_bow.py` 里：


```
@provider(init_hook=initializer, cache=CacheType.CACHE_PASS_IN_MEM)
def process(settings, file_name):
```

其中 `@provider` 是一个 Python decorator，定义在 [`python/paddle/trainer/PyDataProvider2.py`](https://github.com/baidu/Paddle/blob/master/python/paddle/trainer/PyDataProvider2.py) 里：

```
def provider(input_types=None, should_shuffle=None, pool_size=-1,
             min_pool_size=-1,
             can_over_batch_size=True,
             calc_batch_size=None,
             cache=CacheType.NO_CACHE,
             check=False, check_fail_continue=False,
             use_dynamic_order=True,
             init_hook=None, **kwargs):
    """
    Provider decorator. Use it to make a function into PyDataProvider2 object.
    In this function, user only need to get each sample for some train/test
    file.
```

`@provider`是一个有参数的 decorator，相对更简单的[没有参数的decorator](http://jfine-python-classes.readthedocs.io/en/latest/decorators.html)，有参数的 decorator 的描述在[这里](http://stackoverflow.com/questions/5929107/python-decorators-with-parameters).


## 定义 Data Provider

为了细致了解 data provider 机制，我们细致跟踪一下上述 Paddle 程序 `trainer_config.lr.py` 的执行过程。这个过程是从 [`trian.sh`](https://github.com/baidu/Paddle/blob/master/demo/quick_start/train.sh) 开始的：

```
paddle train \
  --config=trainer_config.lr.py \
  --save_dir=./output \
  --trainer_count=4 \
  --log_period=20 \
  --num_passes=15 \
  --use_gpu=false \
  --show_parameter_stats_period=100 \
  --test_all_data_in_one_period=1 \
  2>&1 | tee 'train.log'
```

当执行 paddle 命令时，paddle 会执行 `--config` 指定的 Python 程序 `trianer_config.lr.py`。这个程序指定 data provider、描述（深度）神经元网络、并且启动训练或者测试或者预测任务。其中指定 data provider 的部分在上文中已经见到了，是通过调用 `define_py_data_sources2` 做到的。


`define_py_data_sources2` 的定义在 [`python/paddle/trainer_config_helpers/data_sources.py`](https://github.com/baidu/Paddle/blob/master/python/paddle/trainer_config_helpers/data_sources.py)，只是简单地调用了另一个函数 [`define_py_data_sources`](https://github.com/baidu/Paddle/blob/master/python/paddle/trainer_config_helpers/data_sources.py#L97)：

```
    define_py_data_sources(train_list=train_list,
                           test_list=test_list,
                           module=module,
                           obj=obj,
                           args=args,
                           data_cls=None)
```

而  [`define_py_data_sources`](https://github.com/baidu/Paddle/blob/master/python/paddle/trainer_config_helpers/data_sources.py#L97) 调用了两次 [`define_py_data_source2`](https://github.com/baidu/Paddle/blob/master/python/paddle/trainer_config_helpers/data_sources.py#L29)：

```
        define_py_data_source(file_list=train_list, cls=TrainData, module, obj, args, 
                train_async=False, data_cls=None)

        define_py_data_source(file_list=test_list, cls=TestData, module, obj, args, 
                train_asycn=False, data_cls=None)
```

[`define_py_data_source2`](https://github.com/baidu/Paddle/blob/master/python/paddle/trainer_config_helpers/data_sources.py#L29) 做了如下工作：


1. 如果 `file_list` 是一个 Python list，则将其转换成一个列出数据文件的文本文件


1. 因为上面里子里的参数 `data_cls` 是 `None`，所以 `define_py_data_source` 把 `data_cls` 设置为嵌套定义的函数 [`py_data2`](https://github.com/baidu/Paddle/blob/master/python/paddle/trainer_config_helpers/data_sources.py#L79)。 

   ```
       if data_cls is None:
        def py_data2(files, load_data_module, load_data_object, load_data_args,
                    **kwargs):
            data = DataBase()
            data.type = 'py2'
            data.files = files
            data.load_data_module = load_data_module
            data.load_data_object = load_data_object
            data.load_data_args = load_data_args
            return data
        data_cls = py_data2
   ```

   `py_data2` 调用 [`DataBase()`](https://github.com/baidu/Paddle/blob/master/python/paddle/trainer/config_parser.py#L788)，这个函数创建一个 protobuf message `DataConfig`，然后往里填写一些信息来描述一个数据源，其中一项很重要的信息是数据源的类型 `DataConfig.type=“py2”`。在下文中我们会看到这个数据类型和作用。


1. 随后，`define_py_data_source` 调用函数 `cls`。在上例中，`cls` 的值是 [`TrainData`](https://github.com/baidu/Paddle/blob/master/python/paddle/trainer/config_parser.py#L938) 或者 [`TestData`](https://github.com/baidu/Paddle/blob/master/python/paddle/trainer/config_parser.py#L950)：

   ```
       cls(data_cls(files=file_list,
                 load_data_module=module,
                 load_data_object=obj,
                 load_data_args=args,
                 async_load_data=async))
   ```

   `TrainData` 和 `TestData` 并没有做太多工作。它们主要是吧 `DataConfig` 变量记录到全局变量 `g_config` 里.


## 调用 Data Provider

上例中，`module` 和 `obj` 参数被填写近 `DataConfig.load_data_module` 和 `DataConfig.load_data_object` 里了。这两个 fields 被一个 C++ class [`PyDataProvider2`](http://162.243.141.242/paddle_html/codebrowser/codebrowser/paddle/gserver/dataproviders/PyDataProvider2.cpp.html#paddle::PyDataProvider2) 使用。

在 `PyDataProvider2` 的定义的下面，有[一行](http://162.243.141.242/paddle_html/codebrowser/codebrowser/paddle/gserver/dataproviders/PyDataProvider2.cpp.html#667)：

```
REGISTER_DATA_PROVIDER_EX(py2, PyDataProvider2);
```

宏 `REGISTER_DATA_PROVIDER_EX` 的定义在[这里](http://162.243.141.242/paddle_html/codebrowser/codebrowser/paddle/gserver/dataproviders/DataProvider.h.html#_M/REGISTER_DATA_PROVIDER_EX)：

```
#define REGISTER_DATA_PROVIDER_EX(__type_name, __class_name)            \
  static InitFunction __reg_type_##__type_name([] {                     \
  DataProvider::registrar_.registerClass<__class_name>(#__type_name);   \
})
```

它负责把 `__type_name` （在我们的例子是 “py2”）和 `__class_name` （在我们的例子里是 PyDataProvider2）登记到  class `DataProvider` 的 static member [`registrar_`](http://162.243.141.242/paddle_html/codebrowser/codebrowser/paddle/gserver/dataproviders/DataProvider.h.html#_ZN6paddle12DataProvider10registrar_E) 里：

```
class DataProvider {
public:
  static ClassRegistrar<DataProvider, DataConfig, ModelConfig, bool> registrar_;
```

其中，class template `ClassRegistrar`的定义在[这里](http://162.243.141.242/paddle_html/codebrowser/codebrowser/paddle/utils/ClassRegistrar.h.html#44)。它维护一个从class的名字到其creator函数的映射：

```
template <class BaseClass, typename... CreateArgs>
class ClassRegistrar {
  typedef std::function<BaseClass*(CreateArgs...)> ClassCreator;
  std::map<std::string, ClassCreator> creatorMap_;
```

`DataProvider::registrar_` 被成员函数 [`DataProvider::create`](http://162.243.141.242/paddle_html/codebrowser/codebrowser/paddle/gserver/dataproviders/DataProvider.cpp.html#_ZN6paddle12DataProvider6createERKNS_10DataConfigERKNS_11ModelConfigEb) 用来创建一个 data provider：

```
DataProvider* DataProvider::create(const DataConfig& config,
                                   const ModelConfig& modelConfig,
                                   bool useGpu) {
  return registrar_.createByType(config.type(), config, modelConfig, useGpu);
}
```

`DataProvider::create` 又被 [`Trainer::init`](http://162.243.141.242/paddle_html/codebrowser/codebrowser/paddle/trainer/Trainer.cpp.html#196) 调用。

```
if (!dataProvider_ && config_->hasDataConfig()) {
    dataProvider_.reset(DataProvider::create(*config_, *config_, gpuData));
}
```

这个调用返回的 data provider 被保存在数据成员 [`Trainer::dataProvider_`](http://162.243.141.242/paddle_html/codebrowser/codebrowser/paddle/trainer/Trainer.h.html#paddle::Trainer::dataProvider_) 里。


`Trainer::dataProvider_` 被 [`Trainer::train`](http://162.243.141.242/paddle_html/codebrowser/codebrowser/paddle/trainer/Trainer.cpp.html#274) 传递给 gradient machine 的 `start` 成员函数:

```
void Trainer::train(size_t numPasses) {
  ...
  trainerInternal_.getGradientMachine()->start(*config_, dataProvider_);
  ... 
```

这个 `start` 函数会调用 `PyDataProvider2::createPyData` 和 `PyDataProvider2::readByFields` 来创建需要的 Python 函数 —— 也就是文首提到的 `process` —— 来读取数据。

随后 `Trainer::train` 执行一个循环，迭代地更新模型参数。每个迭代结束的时候会调用 data provider 的 `reset`函数，来通知 data provider 一次扫描结束。 

```
for (size_t i = 0; i < numPasses; ++i) {
    ...
    if (i < numPasses - 1) {
      dataProvider_->reset();
    }
}
```

Data provider 可以利用这个机会，更新 cache，这样下一个迭代对数据的扫描就不需要从磁盘读取，而是可以利用已经缓存在内存中的备份了：
