# Checklist

## DI 模块
- [x] `Bean`、`BeanDefinition`、`BeanScope` 结构定义完整
- [x] `Container` 提供 register_singleton/register_factory/bind_instance API
- [x] `Container.get[T]` 做类型校验，不匹配返回明确错误
- [x] singleton 作用域：多次 get 返回同一实例
- [x] prototype 作用域：多次 get 返回新实例
- [x] request 作用域：子容器隔离正确
- [x] lazy bean 首次 get 才触发 factory
- [x] 接口绑定 bind_instance 工作正常
- [x] 旧 API（Builder/Service/inject_on/get[T]）作为兼容别名仍可编译
- [x] `di_test.v` 覆盖所有作用域、类型校验、接口绑定、lazy

## 框架集成
- [x] Application 持有独立 Container（非全局默认）
- [x] app.register_singleton/register_factory/bind_instance 可用
- [x] app.inject_on 保留兼容
- [x] Context.di[T] 先查 request 容器再查 root
- [x] handle 中 resp 与 req_ctx.resp 一致，响应体不丢失
- [x] mount[T] 支持接口类型字段注入
- [x] mount[T] 去除 macos/else 平台分支
- [x] request 作用域受 enable_request_scope 开关控制

## 验证器
- [x] Required 支持 int/i64/u64/f64/bool/指针
- [x] Min/Max 支持 f64 字段
- [x] validate 中 rule 解析逻辑无 mut 覆盖隐患
- [x] Number/Regexp/Url 对数值字段行为正确
- [x] validate_test.v 覆盖新分支

## 会话
- [x] SessionStore 接口定义完整
- [x] MemorySessionStore 作为默认实现
- [x] Session 持有 &SessionStore
- [x] get 过期逻辑修复（返回空 map 且 exists=false）
- [x] app.set_session_store 可替换存储

- [x] Configuration 新增 profile/enable_request_scope/max_request_scope_size
- [x] event 模块：EventBus register/emit/off 线程安全
- [x] 内置事件 ServerStart/ServerShutdown/RequestStart/RequestEnd 触发
- [x] README 增加 DI 与事件章节
- [x] examples/example.v 演示新用法

## 验证
- [x] `v test .` 全部通过
- [x] `v build .` 无警告
- [x] examples 编译通过
- [x] 代码已提交到远程分支并生成 PR
