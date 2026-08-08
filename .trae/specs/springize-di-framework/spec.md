# 类 Spring DI 与框架深度优化 Spec

## Why
当前 `very` 框架的 DI 模块仅是"服务名 → voidptr"的简单字典，缺乏作用域、生命周期、接口绑定、工厂、类型安全等 Spring 核心能力；框架层面在控制器挂载、验证器、会话存储、配置管理等方面也存在心智负担高、扩展性差的问题。本次优化旨在以 Spring 的核心设计为参照，在 V 语言能力范围内，把 DI 模块升级为具备作用域、生命周期、接口绑定、工厂、类型校验的容器，并同步优化框架其它模块，使整体"功能合理、逻辑正确、方便易用、没有心智负担"。

## What Changes

### DI 模块（核心重写）
- 重命名 `Builder` → `Container`，`Service` → `Bean`，引入 `BeanDefinition` 元数据结构
- 引入 `BeanScope` 枚举：`singleton` / `prototype` / `request`
- 引入 `BeanDefinition`：name、type、scope、factory、init_method、deinit_method、lazy、primary、qualifiers
- 支持接口绑定：`bind[Interface, Impl]()` / `bind_instance[Interface](impl)`
- 支持工厂注册：`register_factory[T](factory fn() &T, name ...string)`
- 支持 lazy 初始化：lazy bean 首次 `get` 时才构造
- 支持 prototype 作用域：每次 `get` 返回新实例
- 支持 request 作用域：每个 HTTP 请求独立容器（基于 Context）
- 类型校验：`get[T]` 校验存储类型与请求类型一致，不一致返回明确错误
- 保留全局默认容器，但提供 `new_container()` 用于隔离与测试
- `Container` 提供 `has`、`get`、`get_or_default`、`remove`、`clear`、`names`、`count` 等完整 API
- 保留向后兼容的 `di.inject_on`、`di.get[T]` 包级函数（委托给默认容器）

### 框架集成
- `Application` 持有根 `Container`，`Context` 持有 request 作用域子容器
- `Context.di[T](name)` 支持从 request → root 容器逐级查找
- `app.inject_on` 重命名为 `app.register_singleton`（保留旧名兼容）
- 控制器挂载 `mount[T]` 重构：去除冗余平台分支，统一字段注入逻辑，支持接口类型字段注入
- `GroupRouter` 携带 `&Container` 引用，子分组继承父容器

### 验证器优化
- `Validators` 支持注册自定义验证器（已有 `register_validator`，补全文档与示例）
- 验证器支持 `int/i64/u64/f64` 等数值类型字段（当前仅 string）
- 修复 `Required` 仅支持 string 的问题，扩展到数值/bool/指针
- 修复 `validate` 中 `rule` 变量被 `mut` 修改导致后续逻辑异常的隐患

### 会话优化
- 抽象 `SessionStore` 接口：`get`/`set`/`delete`/`exists`/`gc`
- 内存实现 `MemorySessionStore` 作为默认
- `Session` 持有 `&SessionStore`，便于替换为 Redis/DB 实现
- 修复 `SessionStore.get` 中过期删除后仍返回空 data 的逻辑问题

### 配置优化
- `Configuration` 增加 `profile string` 字段（dev/test/prod）
- 增加 `enable_request_scope bool` 开关，控制是否启用 request 作用域容器
- 增加 `max_request_scope_size int` 限制 request 容器容量

### 事件机制（轻量）
- 新增 `event` 模块：`Event` 接口、`EventListener` 接口、`EventBus`
- `Application` 持有 `EventBus`，提供 `on`/`emit`/`off`
- 内置事件：`ServerStart`、`ServerShutdown`、`RequestStart`、`RequestEnd`

### 中间件与错误处理
- `Context` 增加 `error_handler` 字段，允许局部覆盖 `recover_handler`
- `Context.abort` 后允许后续中间件感知（通过 `is_stopped`）
- 修复 `Application.handle` 中 `resp` 局部变量与 `req_ctx.resp` 不一致导致响应体丢失的 bug

## Impact
- Affected specs: DI、Application、Context、Validator、Session、Configuration
- Affected code:
  - `di/builder.v`、`di/service.v`、`di/di_test.v`（重写）
  - `app.v`（Container 集成、mount 重构、handle 修复）
  - `context.v`（request 作用域、di 查找链）
  - `configuration.v`（新字段）
  - `validator/*.v`（类型扩展、bug 修复）
  - `session/*.v`（Store 抽象）
  - 新增 `event/` 模块
  - `examples/example.v`、`README.md`（同步示例）

## ADDED Requirements

### Requirement: Bean 定义与元数据
系统 SHALL 提供 `BeanDefinition` 结构，记录 bean 的 name、type、scope、factory、init_method、deinit_method、lazy、primary 等元数据，作为容器注册与解析的依据。

#### Scenario: 注册带元数据的 bean
- **WHEN** 用户调用 `container.register_singleton[T](instance, name)` 或 `container.register_factory[T](factory, name)`
- **THEN** 容器内部生成 `BeanDefinition` 并存储，`container.has(name)` 返回 true

### Requirement: Bean 作用域
系统 SHALL 支持三种作用域：`singleton`（默认，全局唯一）、`prototype`（每次 get 返回新实例）、`request`（每个 HTTP 请求内唯一）。

#### Scenario: singleton 作用域
- **WHEN** 用户注册 singleton bean 并多次 `get[T](name)`
- **THEN** 每次返回同一实例指针

#### Scenario: prototype 作用域
- **WHEN** 用户注册 prototype factory bean 并多次 `get[T](name)`
- **THEN** 每次调用 factory 返回新实例

#### Scenario: request 作用域
- **WHEN** 启用 request scope 且在请求处理中调用 `ctx.di[T](name)`
- **THEN** 同一请求内多次获取返回同一实例，不同请求间相互隔离

### Requirement: 接口绑定
系统 SHALL 支持将一个接口类型绑定到具体实现实例，使得通过接口类型名或显式 name 可获取实现。

#### Scenario: 绑定接口到实例
- **WHEN** 用户调用 `container.bind_instance[Interface](impl)` 后 `container.get[Interface]()`
- **THEN** 返回绑定的实现实例

### Requirement: 类型安全检索
系统 SHALL 在 `get[T](name)` 时校验存储 bean 的类型字符串与请求类型 `T` 一致，不一致时返回明确错误而非 undefined behavior。

#### Scenario: 类型不匹配
- **WHEN** 用户以 `&sqlite.DB` 注册，以 `&int` 获取
- **THEN** 返回 `error('bean type mismatch: expected &int, got &sqlite.DB')`

### Requirement: 生命周期钩子
系统 SHALL 支持 bean 的 init_method（构造后调用）与 deinit_method（容器销毁时调用），lazy bean 在首次 get 时触发 init。

#### Scenario: lazy bean 首次获取触发 init
- **WHEN** 用户注册 lazy=true 的 bean 并首次 `get`
- **THEN** factory 被调用、init_method 被执行、实例被缓存

### Requirement: 事件机制
系统 SHALL 提供轻量事件总线，支持 `on(event, listener)`、`emit(event)`、`off(listener)`，并在服务器启动/关闭、请求开始/结束时自动发出内置事件。

#### Scenario: 监听服务器启动
- **WHEN** 用户调用 `app.on('ServerStart', listener)` 后 `app.run()`
- **THEN** 服务器启动时 listener 被调用

### Requirement: Session 存储抽象
系统 SHALL 提供 `SessionStore` 接口与默认 `MemorySessionStore` 实现，允许用户替换为自定义实现。

#### Scenario: 替换会话存储
- **WHEN** 用户调用 `app.set_session_store(custom_store)`
- **THEN** 后续所有会话读写走自定义存储

## MODIFIED Requirements

### Requirement: 控制器挂载与字段注入
控制器通过 `mount[T]()` 挂载时，系统 SHALL 自动解析带 `[inject: 'name']` 标记的字段，支持指针类型与接口类型字段，统一注入逻辑，去除平台分支。

#### Scenario: 接口字段注入
- **WHEN** 控制器字段为接口类型且标记 `[inject: 'name']`
- **THEN** 容器查找 name 对应 bean 并注入到接口字段

### Requirement: Context DI 查找链
`Context.di[T](name)` SHALL 先查 request 作用域容器，未命中再查根容器，均未命中返回错误。

#### Scenario: request 作用域优先
- **WHEN** request 容器与 root 容器都有同名 bean
- **THEN** 返回 request 容器中的实例

## REMOVED Requirements

### Requirement: 旧 Builder/Service 命名
**Reason**: 命名不符合 Spring 习惯，且结构过于简单无法承载新能力
**Migration**: 保留 `di.Builder`/`di.Service` 作为 `Container`/`Bean` 的类型别名与包级兼容函数，旧代码无需改动即可编译；新增代码使用新命名。
