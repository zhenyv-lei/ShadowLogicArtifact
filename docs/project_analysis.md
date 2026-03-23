# ShadowLogic 项目分析与 Platform Timing Contracts 实验设计文档

## 一、原始论文 (ShadowLogic) 核心思想

### 1.1 问题定义

论文 **"RTL Verification for Secure Speculation Using Contract Shadow Logic"** (ASPLOS 2025) 解决的核心问题是：如何在 RTL 级别高效地形式化验证处理器是否安全地防御了推测执行攻击 (Spectre/Meltdown 等)。

安全性质通过 **软件-硬件契约 (Software-Hardware Contract)** 形式化表达：

```
∀P, M_pub, M_sec, M_sec':
  if O_ISA(P, M_pub, M_sec) = O_ISA(P, M_pub, M_sec')    // 契约约束检查
  then O_μArch(P, M_pub, M_sec) = O_μArch(P, M_pub, M_sec')  // 泄漏断言检查
```

含义：如果一个程序在 ISA 层面不泄露秘密（满足软件约束），那么在微架构层面也不应泄露秘密。

### 1.2 两种契约类型

| 契约 | 软件约束 (O_ISA) | 微架构观测 (O_μArch) |
|------|-----------------|---------------------|
| **Sandboxing** | 程序顺序执行不会将秘密加载到寄存器 | 内存总线地址序列 + 指令提交时间 |
| **Constant-Time** | 程序顺序执行不会用秘密作为地址/分支条件 | 内存总线地址序列 + 指令提交时间 |

### 1.3 验证方案演进

#### Baseline (4-copy) 方案
- 4 个状态机：2 个 ISA 单周期机 + 2 个乱序处理器
- ISA 机做契约约束检查，乱序处理器做泄漏断言检查
- 问题：状态空间巨大，7 天内无法完成证明

#### Contract Shadow Logic (2-copy) 方案 -- 核心创新
- **关键洞察**：如果乱序处理器正确实现了 ISA 语义，那么 ISA trace 可以从乱序处理器的提交序列中重建
- 因此只需 2 个乱序处理器副本 + 影子逻辑，消除了 2 个 ISA 单周期机
- 影子逻辑负责：
  1. 从乱序处理器中提取 ISA trace（监控 commit stage）
  2. 满足 **指令包含要求** (Instruction Inclusion Requirement)
  3. 满足 **同步要求** (Synchronization Requirement)

### 1.4 两阶段影子逻辑实现

```
Phase 1: 逐周期比较两个副本的微架构trace
  -> 检测到微架构偏差时进入 Phase 2

Phase 2:
  -> 排空 pipeline 中的 inflight 指令（满足指令包含要求）
  -> 通过 clock gating 重新对齐 ISA trace（满足同步要求）
  -> 断言：如果出现了微架构偏差，在所有 inflight 指令都被检查后，不应违反契约约束
```

伪代码关键变量：
- `stall_1/stall_2`: 通过门控时钟暂停一个副本，实现 ISA trace 对齐
- `commit_deviation`: 两副本提交时间不同步
- `addr_deviation`: 两副本地址不同
- `finish_1/finish_2`: 偏差后 inflight 指令已排空
- `invalid_program`: 程序违反契约约束

### 1.5 验证流程

1. 实例化两个乱序处理器副本 + 影子逻辑
2. 指令内存使用符号值（model checker 搜索所有可能程序）
3. 写入 assumptions：相同初始状态（秘密除外）+ 契约约束
4. assert 泄漏断言
5. 使用 JasperGold 进行模型检查

### 1.6 评估的处理器

| 处理器 | ISA | 架构 | 影子逻辑代码量 |
|--------|-----|------|---------------|
| Sodor | RV32I | 2级流水线, 顺序 | ~90 行 Verilog |
| SimpleOoO | 4条自定义指令 | 4级流水线, 乱序 | ~100 行 Verilog |
| RideCore | RV32IM (35条) | 6级流水线, 乱序, 超标量 | ~400 行 Verilog |
| BOOM | RV64GC | SmallBOOM 配置, 乱序 | ~240 行 Verilog |

### 1.7 ShadowLogic 的局限性

ShadowLogic 验证的是 **CPU core 在隔离环境下的安全性**：
- 内存集成在 `SodorInternalTile` 内部，固定 1 周期延迟
- 两个 copy 的内存行为完全相同（相同延迟、相同接口）
- **隐含假设**：平台（内存、cache、中断等）不会引入额外的时序通道

这意味着 ShadowLogic 的验证结论**仅在理想平台假设下成立**。当 CPU 被集成到实际 SoC 平台（含 cache、中断控制器等）后，平台组件可能引入新的时序通道，使得隔离验证的结论不再可靠。

---

## 二、我们的研究：Platform Timing Contracts

### 2.1 核心问题

> **当 CPU 从隔离环境集成到 SoC 平台后，ShadowLogic 的安全验证结论是否仍然成立？**

这是 ShadowLogic 与实际部署之间的关键 gap：

```
ShadowLogic 隔离验证:
┌──────────────────────────┐
│ SodorInternalTile         │
│  CPU <-> 内部内存(1周期)   │  <- 内存行为固定，不可观测
│  两个copy的内存行为相同    │
└──────────────────────────┘
-> 验证通过 (但仅在理想假设下)

实际 SoC 部署:
┌──────────────────────────────────────────┐
│  SoC Platform                             │
│  ┌────┐  req/addr  ┌───────┐  ┌──────┐  │
│  │ CPU │ --------> │ Cache  │--│ 主存  │  │
│  │Core │ <-------- │(hit/  │  │(多周期)│  │
│  └────┘  rdata/gnt │miss)  │  └──────┘  │
│                    └───────┘             │
│           不同地址 -> 不同延迟             │
│           -> 秘密可能通过时序泄漏！        │
└──────────────────────────────────────────┘
-> 安全性未知
```

### 2.2 研究思路：Platform Timing Contracts

我们提出 **Platform Timing Contracts (平台时序契约)** 来解决这个问题。核心思路是：

1. 不需要拥有平台的完整 RTL（在 CPU 设计阶段平台 RTL 通常不可得）
2. 用一种简洁的契约语言来**抽象描述平台的时序行为**
3. 将该契约编码为可综合的 **PTCI 仪器化逻辑**，注入到 ShadowLogic 的 miter circuit 中
4. 在不同平台假设下验证 CPU 的安全性

### 2.3 平台时序契约定义

平台时序契约描述 **CPU 输出信号对 CPU 输入信号的影响关系**：

```
C1 (理想内存):
  req   -> diamond{gnt, rdata}     // 只有请求影响时序和数据
  addr  -> diamond{rdata}          // 地址只影响数据，不影响时序
  we    -> diamond{rdata}          // 读写类型只影响数据
  wdata -> diamond{rdata}          // 写数据只影响返回数据

C2 (带 Cache):
  req   -> diamond{gnt, rdata}     // 请求影响时序和数据
  addr  -> diamond{gnt, rdata}     // 地址也影响时序！(cache hit/miss)
  we    -> diamond{gnt, rdata}     // 读写类型也影响时序
  wdata -> diamond{rdata}          // 写数据只影响返回数据

C3 (带中断):
  wdata -> diamond{gnt, rdata, int}  // 写数据还可能触发中断

C4 (条件中断):
  wdata -> diamond{gnt, rdata, int} (if addr in periph_range)
  // 只有写入特定外设地址范围时，数据才影响中断
```

契约层级关系（从强到弱）：C1 > C2 > C3 > C4

C1 最强（允许最少信息流），C4 最弱（允许最多信息流）。
在强契约下验证通过的 CPU，在弱契约下也一定通过。

### 2.4 PTCI 仪器化

**Platform Timing Contract Instrumentation (PTCI)** 是将契约编码为电路逻辑的方法：

#### Sticky-one 算子
实现 diamond 运算符：一旦检测到差异，永久记录。

```verilog
reg sticky_req;
always @(posedge clk) begin
    if (rst) sticky_req <= 0;
    else     sticky_req <= sticky_req | diff_req;
end
```

#### XOR 差异检测
比较两个 CPU 副本的输出信号是否曾经不同：

```verilog
assign diff_req  = copy1.req  ^ copy2.req;
assign diff_addr = |(copy1.addr ^ copy2.addr);  // reduction OR for multi-bit
```

#### PTCI MUX 控制
根据契约允许的信息流，决定 copy2 是否可以收到不同的输入：

```verilog
wire allow_gnt_diff = sticky_req | sticky_addr;  // C2: addr 影响 gnt
wire resp_valid_copy2 = allow_gnt_diff ? unconstrained : shared;
```

---

## 三、实验设计与结果

### 3.1 实验总体目标

证明 **仅验证 CPU 隔离环境下的安全性是不够的**。当 CPU 集成到有 cache 等外部设备的 SoC 平台后，原本被证明安全的防御机制可能不再安全。

### 3.2 核心实验：NoFwd_spectre + CT + Cache

#### 实验背景

ShadowLogic 论文在 SimpleOoO 处理器上评估了多种推测执行防御机制。其中 **NoFwd_spectre** 防御的逻辑是：当 ROB 中有未决分支时，推测执行的 load 指令仍然发射执行，但其结果数据**不转发**给后续指令。

ShadowLogic 论文使用 `OBSV_EVERY_ADDR` 观测模型（观测所有 load 地址，包括推测执行的），在该模型下 NoFwd_spectre + CT 会被找到攻击（0.1s CEX）。

我们采用更现实的 `OBSV_COMMITTED_ADDR` 观测模型（只观测 committed 指令的地址），这对应真实攻击场景——攻击者无法直接窥探 CPU 内部的推测执行地址，只能通过时序侧信道间接推断。

#### 实验配置

| 参数 | Step 1 (隔离) | Step 2 (有 cache) |
|------|-------------|------------------|
| 处理器 | SimpleOoO | SimpleOoO |
| 防御机制 | NoFwd_spectre (`PARTIAL_STT + PARTIAL_STT_USE_SPEC`) | 同左 |
| 软件合约 | CT (Constant-Time) | 同左 |
| 观测模型 | `OBSV_COMMITTED_ADDR` (OBSV=0) | 同左 |
| 内存模型 | 内部 memd, 固定 1 周期延迟 (`USE_CACHE=0`) | 内部 cache, hit=1/miss=3 周期 (`USE_CACHE=1`) |
| 验证引擎 | AM (unbounded proof) | Ht (bounded, 找反例) |

#### 实验结果

| 实验 | 配置 | 结果 | 时间 |
|------|------|------|------|
| **Step 1** | NoFwd + CT + OBSV=0 + 无 cache | **Proven (安全)** | 340.77s (5.7min) |
| **Step 2** | NoFwd + CT + OBSV=0 + 有 cache | **CEX (攻击, 18 cycles)** | 269.35s (4.5min) |

#### 攻击机制分析

```
Step 1 为什么 PASS (无 cache):
  1. 推测 load 发射，地址可能依赖秘密
  2. 但 OBSV=0 不观测推测地址 (addr_deviation 不检查)
  3. 内部内存固定 1 周期延迟，不管什么地址都一样
  4. 两个 copy 的 commit 时间相同 → 无 commit_deviation
  → PASS

Step 2 为什么 FAIL (有 cache):
  1. 推测 load 发射，地址依赖秘密 (通过先前 committed load 加载的秘密值)
  2. OBSV=0 仍然不观测推测地址
  3. 但 cache 引入地址依赖延迟: hit=1周期, miss=3周期
  4. 两个 copy 的推测 load 访问不同地址 → 不同的 cache hit/miss
  5. 不同延迟 → pipeline 状态不同 → committed 指令的 commit 时间不同
  6. commit_deviation 被触发 → assertion FAIL
  → CEX (18 cycles 的攻击序列)
```

#### 实验意义

> **NoFwd_spectre 防御在理想内存（固定延迟）下被形式化证明安全。但当 CPU 集成到有 cache 的平台后（地址依赖延迟），推测 load 的秘密相关地址导致不同的 cache hit/miss 时序，间接泄漏了信息——即使攻击者无法直接观测推测地址。**

这证明了：
1. 仅验证 CPU 隔离安全是不够的
2. 平台组件（cache）的时序行为可以引入新的攻击路径
3. 需要 Platform Timing Contracts 来显式建模平台假设

### 3.3 对比实验汇总

| 实验 | 处理器 | 合约 | 防御 | 观测模型 | 内存 | 结果 | 时间 |
|------|--------|------|------|---------|------|------|------|
| 原始 CT | Sodor | CT | 无 (顺序) | OBSV=1 | Tile 内部 | **Proven** | 4.26s |
| 原始 S-S | SimpleOoO | CT | Delay_spectre | OBSV=1 | 内部 memd | **Proven** | 343s |
| **Step 1** | SimpleOoO | CT | NoFwd_spectre | OBSV=0 | 内部 memd (无cache) | **Proven** | 340.77s |
| **Step 2** | SimpleOoO | CT | NoFwd_spectre | OBSV=0 | 内部 cache (hit/miss) | **CEX** | 269.35s |

### 3.4 实验的论证逻辑

```
前提: NoFwd_spectre 防御在 OBSV_COMMITTED_ADDR 下,
      固定延迟内存环境中被证明安全 (Step 1, 5.7min proof)
         |
问题: 当 CPU 集成到有 cache 的平台后, 还安全吗?
         |
实验: 开启 SimpleOoO 内置的 cache 模型 (USE_CACHE=1)
      cache: single-entry, hit=1 cycle, miss=3 cycles
         |
结果: 4.5 分钟内找到 18 周期的攻击 (Step 2, CEX)
         |
结论: 平台的时序特性 (cache hit/miss) 为推测执行创造了
      新的时序侧信道, 使得原本安全的防御机制失效。
      验证 CPU 安全性时必须考虑平台时序行为。
```

---

## 四、项目代码架构

### 4.1 目录结构

```
ShadowLogicArtifact/
|-- src/                          # 处理器 RTL 源码
|   |-- sodor2/                   # Sodor 2级流水线处理器
|   |   |-- sodor_2_stage.sv      # 核心处理器 RTL (含 SodorInternalTile 和 Core)
|   |   |-- param.vh              # 参数配置 (IMEM/DMEM/RF 大小)
|   |   |-- two_copy_top_ct.sv    # 原始: 2-copy CT 契约验证 (Tile, 内含内存)
|   |   |-- two_copy_top_sandbox.sv  # 原始: 2-copy Sandboxing 契约验证
|   |   |-- two_copy_top_c1.sv    # ★ 新增: Core + C1 PTCI 验证
|   |   |-- two_copy_top_c2.sv    # ★ 新增: Core + C2 PTCI 验证
|   |   |-- four_copy_top_ct.sv   # 原始: 4-copy baseline CT
|   |   |-- four_copy_top_sandbox.sv  # 原始: 4-copy baseline Sandboxing
|   |   +-- sodor_1_stage.sv      # 1级 ISA 机 (baseline 用)
|   |
|   |-- darkriscv/                # DarkRISCV 处理器
|   |   +-- rtl/
|   |       |-- darkriscv.v       # 核心处理器 RTL
|   |       +-- two_copy_top_c1.sv  # ★ 新增: DarkRISCV + C1 PTCI
|   |
|   |-- simpleooo/                # 简单乱序处理器 (含多种防御)
|   |-- ridecore/                 # RideCore 乱序处理器
|   +-- boom/                     # BOOM 乱序处理器
|
|-- verification/                 # JasperGold 验证脚本
|   |-- verify_2_copy_ct_sodor2.tcl      # 原始: 2-copy CT
|   |-- verify_2_copy_sandbox_sodor2.tcl  # 原始: 2-copy Sandboxing
|   |-- verify_2_copy_c1_sodor2.tcl      # ★ 新增: Sodor + C1
|   |-- verify_2_copy_c2_sodor2.tcl      # ★ 新增: Sodor + C2
|   |-- verify_2_copy_c1_darkriscv3.tcl  # ★ 新增: DarkRISCV + C1
|   +-- gen_verify.py                    # 验证脚本生成器
|
|-- results/                      # 实验结果
|   |-- CompareTable/             # 对比表格实验
|   +-- ScalabilityFigure/        # 可扩展性实验
|
+-- scripts/                      # 工具脚本
    |-- dask/                     # 分布式任务执行
    +-- experiment_helper/        # 实验辅助工具
```

### 4.2 核心实现模式对比

#### 原始 ShadowLogic 验证 (two_copy_top_ct.sv)

```
+---------------------------------------------------+
|                    top module                       |
|                                                     |
|  +----------------+    +----------------+           |
|  |   copy1         |    |   copy2         |           |
|  | (SodorTile)     |    | (SodorTile)     |           |
|  |  内含内存        |    |  内含内存        |           |
|  |  1周期固定响应   |    |  1周期固定响应   |           |
|  |                 |    |                 |           |
|  | clk=stall_1?    |    | clk=stall_2?    |           |
|  |   0 : clk       |    |   0 : clk       |           |
|  +--------+--------+    +--------+--------+           |
|           |                      |                   |
|           +----------+-----------+                   |
|                      |                               |
|           +----------v----------+                    |
|           |    Shadow Logic      |                    |
|           |  - commit 比较       |                    |
|           |  - addr 比较         |                    |
|           |  - stall 控制        |                    |
|           |  - drain 检测        |                    |
|           +---------------------+                    |
|                                                     |
|  assume {!invalid_program}    // CT 契约约束          |
|  assert {!(deviation&&drained)} // 泄漏断言           |
+---------------------------------------------------+
```

特点：
- 两个副本使用 `SodorInternalTile`（内含内存）
- 内存行为固定，两个 copy 内存响应完全相同
- **隐含假设**：平台不引入额外时序通道

#### 新增 PTCI 验证 (two_copy_top_c1.sv / c2.sv)

```
+--------------------------------------------------------------+
|                         top module                             |
|                                                                |
|  +-------------+                   +-------------+             |
|  |  copy1       |                   |  copy2       |             |
|  |  (Core)      |                   |  (Core)      |             |
|  |  无内部内存   |                   |  无内部内存   |             |
|  |              |                   |              |             |
|  | imem_req  ---+---XOR-------------+--- imem_req  |             |
|  | dmem_req  ---+---XOR-------------+--- dmem_req  |             |
|  | dmem_addr ---+---XOR-------------+--- dmem_addr |             |
|  |              |                   |              |             |
|  | imem_resp <--+-- shared          | imem_resp <--+-- PTCI_mux |
|  | dmem_resp <--+-- shared          | dmem_resp <--+-- PTCI_mux |
|  +-------------+                   +-------------+             |
|                                                                |
|  +----------------------------------------------------------+  |
|  |                    PTCI Logic                              |  |
|  |                                                            |  |
|  |  diff_req  --> sticky_req   (sticky-one)                  |  |
|  |  diff_addr --> sticky_addr  (sticky-one)                  |  |
|  |  diff_we   --> sticky_we    (sticky-one)                  |  |
|  |  diff_wdata-> sticky_wdata  (sticky-one)                  |  |
|  |                                                            |  |
|  |  C1: allow_gnt_diff   = sticky_req                        |  |
|  |  C2: allow_gnt_diff   = sticky_req | sticky_addr | ...    |  |
|  |      allow_rdata_diff = sticky_req | sticky_addr | ...    |  |
|  |                                                            |  |
|  |  copy2_resp = allow_diff ? unconstrained : shared         |  |
|  +----------------------------------------------------------+  |
|                                                                |
|  +----------------------------------------------------------+  |
|  |                   Shadow Logic (同上)                      |  |
|  +----------------------------------------------------------+  |
|                                                                |
|  assume {!invalid_program}    // CT 契约约束                    |
|  assert {!(deviation&&drained)} // 泄漏断言                     |
+--------------------------------------------------------------+
```

关键区别：
- 使用 `Core`（暴露内存接口），而非 `SodorInternalTile`（内含内存）
- 增加 **PTCI 逻辑**：根据平台时序契约控制两个副本的内存输入
- copy1 始终使用 shared 输入（作为基准）
- copy2 的输入由 PTCI MUX 控制：当契约允许差异时使用 unconstrained 输入
- Shadow Logic 与原始实现相同，仅适配信号名

### 4.3 C1 与 C2 契约的 PTCI 差异

| 特性 | C1 (理想内存) | C2 (带 Cache) |
|------|-------------|--------------|
| req -> gnt | YES (sticky_req) | YES (sticky_req) |
| addr -> gnt | NO | YES (sticky_addr) |
| we -> gnt | NO | YES (sticky_we) |
| allow_gnt_diff | `sticky_req` | `sticky_req \| sticky_addr \| sticky_we` |
| 含义 | 地址不影响时序 | 地址影响时序 (cache hit/miss) |

**核心区别**：C2 的 `allow_gnt_diff` 额外包含 `sticky_addr`，这意味着当两个 copy 的地址曾经不同时，C2 允许它们收到不同时序的响应（模拟 cache hit/miss）。而 C1 下即使地址不同，时序也必须相同（理想内存没有地址依赖的延迟）。

### 4.4 TCL 验证脚本结构

```tcl
# 1. 分析源文件
analyze -sva <source_files>

# 2. 展开设计
elaborate -top top -bbox_mul 256 ...

# 3. 时钟和复位
clock clk
reset rst -non_resettable_regs 0

# 4. 抽象化 (减小状态空间)
abstract -init_value {copy1.regfile}
abstract -init_value {copy2.regfile}

# 5. 约束 (assumptions)
assume {地址范围}
assume {合法指令}
assume {!invalid_program}     # CT 契约约束

# 6. 断言 (assertion)
assert {!((deviation) && drained)}  # 泄漏断言

# 7. 覆盖性检查 (covers) -- PTCI 特有
cover {allow_imem_gnt_diff}        # PTCI 信号可达性
cover {sticky_dmem_addr}           # sticky-one 可达性
cover {diff_dmem_req}              # 差异检测可达性
cover {commit_deviation}           # shadow logic 可达性

# 8. 证明配置
set_engine_mode {AM}           # AM = Abstract Model
set_prove_time_limit 7d
prove -all
```

---

## 五、当前实现进展

### 5.1 核心实验（已完成）

**SimpleOoO NoFwd_spectre + CT + OBSV_COMMITTED_ADDR：**
- `results/veri_nofwd_ct_obsv0_nocache.tcl` -- Step 1: 无 cache → **Proven (340.77s)**
- `results/veri_nofwd_ct_obsv0_cache.tcl` -- Step 2: 有 cache → **CEX (269.35s, 18 cycles)**

**复现实验：**
- `results/veri_ct_2copy_RF4_MEMI16_MEMD4_ROB4_CACHE0_PDOM_OPTMem.tcl` -- Delay_spectre + CT → **Proven (343s)**

**Sodor 基线：**
- 原始 CT (`verification/verify_2_copy_ct_sodor2.tcl`) → **Proven (4.26s)**

### 5.2 早期探索（参考）

**Sodor PTCI 实验（Sodor 为顺序处理器，无推测执行，cache 不影响安全性）：**
- `src/sodor2/two_copy_top_c1.sv` -- Core + C1 PTCI
- `src/sodor2/two_copy_top_c2.sv` -- Core + C2 PTCI
- `verification/verify_2_copy_c1_sodor2.tcl`, `verify_2_copy_c2_sodor2.tcl`

**DarkRISCV PTCI 实验：**
- `src/darkriscv/rtl/two_copy_top_c1.sv` -- DarkRISCV + C1 PTCI

### 5.3 待实现

| 任务 | 优先级 | 说明 |
|------|-------|------|
| 分析 Step 2 的 counterexample trace | 高 | 确认攻击路径是 cache hit/miss 时序差异 |
| 更多防御机制 + cache 对比 | 高 | 例如 Delay_spectre + cache 是否仍然 PASS |
| RideCore + cache 实验 | 中 | 在更大的乱序处理器上验证 |
| BOOM TileLink + PTCI | 低 | 扩展到 L2 cache 场景 |
| 实验文档和论文写作 | 高 | 整理实验结果用于论文 |

---

## 六、关键设计决策

### 6.1 CPU 模块选择

使用暴露内存接口的 `Core` 模块（而非内含内存的 `Tile`），使 PTCI 可以控制内存输入。

### 6.2 PTCI 位置

PTCI 置于 top module 中，介于"平台抽象"和"CPU 副本"之间。它不修改 CPU 内部逻辑，仅控制外部输入。

### 6.3 copy1 vs copy2 的角色

- copy1: 始终使用 shared 输入，作为"基准执行"
- copy2: 输入由 PTCI MUX 控制，模拟"可能不同的平台响应"

### 6.4 Shadow Logic 复用

影子逻辑与原始 ShadowLogic 实现相同（commit 比较、stall 控制、drain 检测），仅适配信号名（`Core` vs `SodorInternalTile` 的信号路径差异）。

### 6.5 覆盖性检查

增加 cover 语句验证 PTCI 信号是否可达，确保 PTCI 逻辑不是"死代码"：
- `cover {sticky_*}`: sticky-one 能否被触发
- `cover {allow_*_diff}`: PTCI MUX 能否切换到 unconstrained
- `cover {diff_*}`: 两个 copy 的输出是否真的会不同

---

## 七、工具链信息

- **形式化验证工具**: Cadence JasperGold FPV App (`/opt/cadence/jasper_2025.06/bin`)
- **HDL 语言**: Verilog / SystemVerilog
- **断言语言**: SystemVerilog Assertions (SVA)
- **分布式执行**: Dask Python 集群
- **处理器 ISA**: RISC-V (RV32I / RV32IM / RV64GC)
