# Tasks

## Phase 1: DI 容器核心重写
- [ ] Task 1: 重写 `di/service.v` 为 `di/bean.v`，定义 `Bean`、`BeanDefinition`、`BeanScope`
  - [ ] SubTask 1.1: 定义 `BeanScope` 枚举（singleton/prototype/request）
  - [ ] SubTask 1.2: 定义 `BeanDefinition` 结构（name/type/scope/factory/init/deinit/lazy/primary）
  - [ ] SubTask 1.3: 定义 `Bean` 结构（definition + instance + initialized 标志）
  - [ ] SubTask 1.4: 保留 `Service`/`new_service` 作为兼容别名
- [ ] Task 2: 重写 `di/builder.v` 为 `di/container.v`，实现 `Container`
  - [ ] SubTask 2.1: 定义 `Container` 结构（mutex + beans map + parent ref）
  - [ ] SubTask 2.2: 实现 `register_singleton[T]`、`register_factory[T]`、`bind_instance[T]`
  - [ ] SubTask 2.3: 实现 `get[T]`（带类型校验）、`get_or_default[T]`、`has`、`remove`、`clear`、`names`、`count`
  - [ ] SubTask 2.4: 实现 lazy 初始化与 prototype 作用域逻辑
  - [ ] SubTask 2.5: 实现 `create_request_container()` 返回带 parent 的子容器
  - [ ] SubTask 2.6: 保留 `Builder`/`new_builder`/`default_builder`/`inject_on`/`get[T]` 等兼容 API 委托给默认容器
- [ ] Task 3: 编写 `di/di_test.v` 覆盖各作用域、接口绑定、类型校验、lazy、prototype
  - [ ] SubTask 3.1: singleton 多次 get 返回同一实例
  - [ ] SubTask 3.2: prototype 多次 get 返回不同实例
  - [ ] SubTask 3.3: 接口绑定 get 返回实现
  - [ ] SubTask 3.4: 类型不匹配 get 返回错误
  - [ ] SubTask 3.5: lazy bean 首次 get 触发 factory
  - [ ] SubTask 3.6: request 子容器隔离

## Phase 2: 框架集成
- [ ] Task 4: 修改 `app.v`，Application 持有根 Container，集成事件总线
  - [ ] SubTask 4.1: `Application.di` 改为 `&di.Container`，`new()` 创建独立容器（不再用全局默认）
  - [ ] SubTask 4.2: 新增 `app.register_singleton[T]`/`app.register_factory[T]`/`app.bind_instance[T]`，保留 `app.inject_on` 兼容
  - [ ] SubTask 4.3: 新增 `app.on`/`app.emit`/`app.off` 委托给 EventBus
  - [ ] SubTask 4.4: `run()` 启动前 emit `ServerStart`，`graceful_shutdown` emit `ServerShutdown`
  - [ ] SubTask 4.5: 修复 `handle` 中 `resp` 与 `req_ctx.resp` 不一致导致响应体丢失的 bug
- [ ] Task 5: 修改 `context.v`，Context 持有 request 容器与 DI 查找链
  - [ ] SubTask 5.1: `Context` 增加 `di_container &di.Container` 字段（request 作用域，可为 nil）
  - [ ] SubTask 5.2: `Context.di[T](name)` 改为先查 request 容器再查 root
  - [ ] SubTask 5.3: `Application.handle` 中为每个请求创建 request 子容器（受配置开关控制）
  - [ ] SubTask 5.4: `Context.reset` 清理 request 容器引用
- [ ] Task 6: 重构 `mount[T]` 与 `warp_handler`，统一字段注入逻辑
  - [ ] SubTask 6.1: `get_injected_fields[T]` 支持接口类型字段（无 indirections 时按接口处理）
  - [ ] SubTask 6.2: 去除 `warp_handler` 中的 macos/else 平台分支，统一指针赋值
  - [ ] SubTask 6.3: 修复 `&${field.name}` 与 `field.name` 双 key 的混乱逻辑，统一为一种 key 策略
  - [ ] SubTask 6.4: 验证 `examples/example.v` 中 App 控制器注入仍工作

## Phase 3: 验证器优化
- [ ] Task 7: 扩展验证器类型支持与修复 bug
  - [ ] SubTask 7.1: `Required` 支持 int/i64/u64/f64/bool/指针（非零值判断）
  - [ ] SubTask 7.2: `Min`/`Max` 已支持数值类型，补全 f64 字段分支
  - [ ] SubTask 7.3: 修复 `validate` 中 `mut rule` 被覆盖后 `validator_rule` 仍用旧值的隐患
  - [ ] SubTask 7.4: `Number`/`Regexp`/`Url` 支持数值字段（Number 对数值直接返回 ok）
  - [ ] SubTask 7.5: 补全 `validate_test.v` 用例覆盖新分支

## Phase 4: 会话优化
- [ ] Task 8: 抽象 SessionStore 接口与默认内存实现
  - [ ] SubTask 8.1: 定义 `SessionStore` 接口（get/set/delete/exists/gc）
  - [ ] SubTask 8.2: 现有逻辑提取为 `MemorySessionStore`
  - [ ] SubTask 8.3: `Session` 持有 `&SessionStore`，所有读写走 store
  - [ ] SubTask 8.4: 修复 `get` 过期删除后返回空 data 的逻辑（应返回空 map 并标记不存在）
  - [ ] SubTask 8.5: `Application` 提供 `set_session_store` 配置入口

## Phase 5: 配置优化
- [ ] Task 9: 扩展 Configuration
  - [ ] SubTask 9.1: 新增 `profile`、`enable_request_scope`、`max_request_scope_size` 字段
  - [ ] SubTask 9.2: 默认值合理（profile='dev'，enable_request_scope=false）

## Phase 6: 事件模块
- [ ] Task 10: 新建 `event/` 模块
  - [ ] SubTask 10.1: 定义 `Event` 接口（name + data）、`EventListener` 接口（on(event)）
  - [ ] SubTask 10.2: 实现 `EventBus`（register/emit/off，线程安全）
  - [ ] SubTask 10.3: 内置事件结构：`ServerStartEvent`、`ServerShutdownEvent`、`RequestStartEvent`、`RequestEndEvent`

## Phase 7: 文档与示例
- [ ] Task 11: 更新 README 与 example
  - [ ] SubTask 11.1: README 增加 DI 章节（singleton/prototype/request/接口绑定/工厂）
  - [ ] SubTask 11.2: README 增加事件机制章节
  - [ ] SubTask 11.3: `examples/example.v` 演示新 DI 用法（工厂、接口绑定、事件监听）

## Phase 8: 验证与提交
- [ ] Task 12: 编译与测试验证
  - [ ] SubTask 12.1: `v test .` 全部通过
  - [ ] SubTask 12.2: `v build .` 无警告
  - [ ] SubTask 12.3: examples 编译通过
- [ ] Task 13: 自审 checklist.md 全部勾选
- [ ] Task 14: 提交到远程并生成 PR

# Task Dependencies
- Task 2 依赖 Task 1
- Task 3 依赖 Task 2
- Task 4 依赖 Task 2
- Task 5 依赖 Task 4
- Task 6 依赖 Task 4、Task 5
- Task 8 依赖 Task 4（set_session_store 入口）
- Task 10 可与 Task 4 并行（event 模块独立）
- Task 11 依赖 Task 4、Task 5、Task 6、Task 10
- Task 12 依赖所有前置 Task
- Task 13 依赖 Task 12
- Task 14 依赖 Task 13
