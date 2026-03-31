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

1. 证明 **仅验证 CPU 隔离环境下的安全性是不够的**
2. 展示 **Soccontract 双向合同框架** 能发现问题、定位问题、指导修复
3. 实现 CPU 和平台的 **解耦验证**

### 3.2 合约层级定义

| 合约 | 允许的信息流 | 对应平台 | 新增（相比上一级） |
|------|------------|---------|------------------|
| **C1** | req→◇{gnt,rdata}, addr→◇{rdata}, wdata→◇{rdata} | 理想内存 | （基准） |
| **C2** | +addr→◇{gnt,rdata}, +we→◇{gnt,rdata} | + Cache | addr 可影响 gnt |
| **C3** | +wdata→◇{gnt,rdata,int} | + 中断控制器 | wdata 可影响 gnt 和 int |

C1 最强（对平台要求最高），C3 最弱（允许最多信息流）。满足 C1 的平台一定满足 C2，反之不然。

### 3.3 验证术语

| 术语 | 含义 | 验证方法 |
|------|------|---------|
| **CPU_C1** | CPU 在 C1 平台假设下是否安全 | CPU miter + C1 PTCI（only sticky_req → allow_gnt_diff） |
| **CPU_C2** | CPU 在 C2 平台假设下是否安全 | CPU miter + C2 PTCI（sticky_req\|sticky_addr → allow_gnt_diff） |
| **CPU_C3** | CPU 在 C3 平台假设下是否安全 | CPU miter + C3 PTCI（+sticky_wdata → allow_gnt_diff, allow_int_diff） |
| **Platform_C1** | 平台是否满足 C1 合约 | Platform miter，检查 addr→gnt 不存在 |
| **Platform_C2** | 平台是否满足 C2 合约 | Platform miter，检查 wdata→gnt 不存在 |
| **Platform_C3** | 平台是否满足 C3 合约 | Platform miter，待定义 |

### 3.4 实验背景

**处理器：**
- **SimpleOoO**：自制乱序处理器，支持 LI/ADD/MUL/LD/ST/BR 6 条指令，4-entry ROB
  - NoFwd_spectre 防御：推测 load 发射但不转发数据
  - Delay_spectre 防御：推测 load 不发射，等到 commit
- **Sodor**：开源顺序处理器，RV32I，2 级流水线，有中断接口

**软件合约**：CT（Constant-Time），OBSV_COMMITTED_ADDR 观测模型

**平台模块：**
- Regular Cache：单条目缓存，hit=1周期/miss=3周期
- Cache-S：固定延迟缓存，所有访问1周期

### 3.5 全部实验结果

#### 第一组：发现问题（SimpleOoO）

| 编号 | 实验 | 结果 | 时间 | 说明 |
|------|------|------|------|------|
| E1 | NoFwd + 无 cache（隔离） | **Proven** | 212s | CPU 在隔离环境下安全 |
| E2 | NoFwd **CPU_C2** | **CEX** (16 cycles) | 32.91s | PTCI 发现 cache 平台引入漏洞 |
| E3 | NoFwd + Cache_regular（组合） | **CEX** (16 cycles) | 60.55s | 用真实 cache 确认同样的漏洞 |

- E1 vs E2：PTCI 在没有 cache RTL 的情况下发现了攻击
- E2 vs E3：PTCI 比真实 cache 更快（33s vs 61s），且结果一致

#### 第二组：Soccontract CPU 侧验证（CPU_Ci）

| 编号 | 处理器 | 防御 | 合约 | 结果 | 时间 |
|------|--------|------|------|------|------|
| E2 | SimpleOoO | NoFwd | **CPU_C2** | **CEX** | 32.91s |
| E4 | SimpleOoO | NoFwd | **CPU_C1** | **Proven** | 652s |
| E5 | SimpleOoO | Delay | **CPU_C1** | **Proven** | 207s |
| E6 | SimpleOoO | Delay | **CPU_C2** | **Proven** | 8118s |
| E7 | Sodor | — (顺序) | **CPU_C1** | **Proven** | 4.82s |
| E8 | Sodor | — (顺序) | **CPU_C2** | **Proven** | 7.76s |
| E9 | Sodor | — (顺序) | **CPU_C4** (无PMP) | **CEX** (7 cycles) | 0.44s |
| — | Sodor | PMP | **CPU_C4** (有PMP) | **Proven** | 5.08s |

#### 第三组：Soccontract 平台侧验证（Platform_Ci）

| 编号 | 平台 | 合约 | 结果 | 时间 |
|------|------|------|------|------|
| E10 | Regular Cache | **Platform_C1** | **CEX** (1 cycle) | 0.08s |
| E11 | Regular Cache | **Platform_C2** | **Proven** | 0s |
| E12 | Cache-S | **Platform_C1** | **Proven** | 0s |
| E16 | 中断控制器 | **Platform_C2** | **CEX** (2 cycles) | 0.08s |
| E17 | 中断控制器 | **Platform_C3** | **Proven** | 0s |

#### 第四组：组合验证

| 编号 | CPU | 平台 | 结果 | 时间 | 说明 |
|------|-----|------|------|------|------|
| E3 | NoFwd | Cache_regular | **CEX** | 60.55s | 不兼容组合 |
| E13 | NoFwd | Cache-S | **Proven** | 207s | 修复平台侧 |
| E14 | Delay | Cache-S | **Proven** | 185.80s | 两侧都修复 |
| E15 | Delay | Cache_regular | **Undetermined** | 7天超时 | 修复 CPU 侧（组合验证超时） |
| — | Sodor-S | 中断控制器 | **Proven** | 1.70s | C4 修复后组合验证 |

#### CPU_Ci 汇总表

| CPU | CPU_C1 | CPU_C2 | CPU_C4 |
|-----|--------|--------|--------|
| SimpleOoO NoFwd | **PASS** (652s) | **FAIL** (33s) | — |
| SimpleOoO Delay | **PASS** (207s) | **PASS** (8118s) | — |
| Sodor | **PASS** (4.82s) | **PASS** (7.76s) | **FAIL** (0.44s) |
| Sodor-S (PMP) | — | — | **PASS** (5.08s) |

#### Platform_Ci 汇总表

| Platform | Platform_C1 | Platform_C2 | Platform_C3 |
|----------|-------------|-------------|-------------|
| Regular Cache | **FAIL** (0.08s) | **PASS** (0s) | **PASS** (蕴含) |
| Cache-S | **PASS** (0s) | **PASS** (蕴含) | **PASS** (蕴含) |
| 中断控制器 | **FAIL** | **FAIL** (0.08s) | **PASS** (0s) |

注：C3 shadow logic 修改了 `invalid_program` 检查，区分程序发起的 PC 变化和中断发起的 PC 变化。中断引起的控制流差异不被视为"程序违反 CT"，而是平台行为导致的可观测差异。

### 3.6 论证逻辑

#### 论点 1：PTCI 能在没有平台 RTL 的情况下发现漏洞

```
E1: NoFwd + 无 cache      → PASS  (隔离安全)
E2: NoFwd CPU_C2           → FAIL  (PTCI 发现漏洞, 32.91s)
E3: NoFwd + Cache_regular  → FAIL  (真实 cache 确认, 60.55s)

PTCI 不需要 cache RTL，仅凭合约描述即可发现相同漏洞，且更快。
```

#### 论点 2：Soccontract 通过合约层级定位不兼容

**C1/C2 层级（SimpleOoO + Cache）：**

```
CPU 侧:
  NoFwd CPU_C2 → FAIL    "NoFwd 不满足 C2"
  NoFwd CPU_C1 → PASS    "NoFwd 满足 C1"

平台侧:
  Regular Cache Platform_C1 → FAIL   "Regular Cache 不满足 C1"
  Regular Cache Platform_C2 → PASS   "Regular Cache 满足 C2"

匹配分析:
  NoFwd 需要 C1 平台，Regular Cache 只满足 C2 → 不兼容！
```

**C2/C4 层级（Sodor + 中断控制器）：**

```
CPU 侧:
  Sodor CPU_C4 (无PMP) → FAIL    "Sodor 不满足 C4"
  Sodor CPU_C2 → PASS             "Sodor 满足 C2"

平台侧:
  中断控制器 Platform_C2 → FAIL   "中断控制器不满足 C2"
  中断控制器 Platform_C3 → PASS   "中断控制器满足 C3"

匹配分析:
  Sodor 需要 C2 平台，中断控制器只满足 C3 → 不兼容！
```

#### 论点 3：Soccontract 指导修复并实现解耦验证

**C1/C2 修复（SimpleOoO + Cache）：**

方案 A：修复 CPU 侧（升级到 Delay）
```
Delay CPU_C2 → PASS              "升级后 CPU 满足 C2"
Regular Cache Platform_C2 → PASS  "Regular Cache 满足 C2"
→ Delay + Regular Cache → 安全 (合约保证)
```

方案 B：修复平台侧（替换为 Cache-S）
```
NoFwd CPU_C1 → PASS        "NoFwd 满足 C1"
Cache-S Platform_C1 → PASS  "Cache-S 满足 C1"
→ NoFwd + Cache-S → 安全 (合约保证)
补充实验确认: NoFwd + Cache-S → Proven (207s) ✓
```

方案 C：两侧都修复
```
Delay CPU_C2 → PASS
Cache-S Platform_C1 → PASS (C1 蕴含 C2)
→ Delay + Cache-S → 安全
实验确认: Delay + Cache-S → Proven (185.80s) ✓
```

**C4 修复（Sodor + 中断控制器）：**

修复 CPU 侧（增加 PMP 约束）
```
Sodor-S CPU_C4 (PMP) → PASS     "PMP 禁止秘密写入外设地址"
中断控制器 Platform_C3 → PASS    "满足 C3（蕴含 C4）"
→ Sodor-S + 中断控制器 → 安全 (合约保证)
组合实验确认: Sodor-S + 中断控制器 → Proven (1.70s) ✓
```

**E15 组合验证超时的意义：**
```
Delay + Regular Cache 组合验证 → Undetermined (7天超时)
而解耦验证: Delay CPU_C2 PASS + Cache Platform_C2 PASS → 合约已保证安全
→ 解耦验证在组合验证不可行时仍能给出安全性结论
```

#### 结论

Soccontract 双向合同框架的价值：
1. **发现**：无需平台 RTL 即可发现安全隐患（PTCI 比真实 cache 更快）
2. **定位**：通过 CPU_Ci / Platform_Ci 判断问题在 CPU 侧还是平台侧
3. **修复**：可以选择修复任一侧（方案 A/B/C），灵活性高
4. **解耦**：CPU 和平台各自独立验证，通过合约作为接口保证组合安全

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

## 五、实验文件与结果对照

### 5.1 SimpleOoO 实验文件

| 编号 | RTL 顶层 | TCL 脚本 | 结果 |
|------|---------|---------|------|
| E1 | `simpleooo/two_copy_top_ct_ext_mem.v` | `veri_nofwd_ct_obsv0_ext_mem_no_ptci.tcl` | Proven (212s) |
| E2 | `simpleooo/two_copy_top_ct_ptci.v` | `veri_nofwd_ct_obsv0_ptci.tcl` | CEX (32.91s) |
| E3 | `simpleooo/two_copy_top_ct_cache_r.v` | `veri_nofwd_ct_obsv0_cache_r.tcl` | CEX (60.55s) |
| E4 | `simpleooo/two_copy_top_ct_ptci_c1_v2.v` | `veri_nofwd_ct_obsv0_ptci_c1_v2.tcl` | Proven (652s) |
| E5 | `simpleooo/two_copy_top_ct_ptci_c1_v2.v` | `veri_delay_ct_obsv0_ptci_c1.tcl` | Proven (207s) |
| E6 | `simpleooo/two_copy_top_ct_ptci.v` | `veri_delay_ct_obsv0_ptci_c2.tcl` | Proven (8118s) |
| E10 | `simpleooo/cache_miter_c2.v` | `veri_cache_compliance.tcl` (c1_regular) | CEX (0.08s) |
| E11 | `simpleooo/cache_miter_c2.v` | `veri_cache_compliance.tcl` (c2_regular) | Proven (0s) |
| E12 | `simpleooo/cache_miter_c2.v` | `veri_cache_compliance.tcl` (c1_secure) | Proven (0s) |
| E13 | `simpleooo/two_copy_top_ct_cache_s.v` | `veri_nofwd_ct_obsv0_cache_s.tcl` | Proven (207s) |
| E14 | `simpleooo/two_copy_top_ct_cache_s.v` | `veri_delay_ct_obsv0_cache_s.tcl` | Proven (185.80s) |
| E15 | gen_verify.py 生成 | `veri_ct_2copy_..._CACHE1_PDOM_OPTMem.tcl` | 运行中 |

### 5.2 Sodor 实验文件

| 编号 | RTL 顶层 | TCL 脚本 | 结果 |
|------|---------|---------|------|
| E7 | `sodor2/two_copy_top_c1.sv` | `veri_sodor_cpu_c1.tcl` | Proven (4.82s) |
| E8 | `sodor2/two_copy_top_c2.sv` | `veri_sodor_cpu_c2.tcl` | Proven (7.76s) |
| E9 | `sodor2/two_copy_top_c3.sv` | `veri_sodor_cpu_c3.tcl` | CEX (0.39s, 7 cycles) |
| E16 | `sodor2/intctrl_miter_verify.v` | `veri_intctrl_compliance.tcl` (c2) | CEX (0.08s, 2 cycles) |
| E17 | `sodor2/intctrl_miter_verify.v` | `veri_intctrl_compliance.tcl` (c3) | Proven (0s) |

### 5.3 核心 RTL 模块

**SimpleOoO 相关（`src/simpleooo/`）：**

| 文件 | 说明 |
|------|------|
| `cpu_ooo_ext_mem.v` | SimpleOoO CPU，暴露外部 dmem 接口（含 store 写端口） |
| `cache_secure.v` | Cache-S，固定延迟，满足 C1 |
| `cache_regular.v` | Regular Cache，hit/miss 时序，满足 C2 但不满足 C1 |
| `cache_miter_c2.v` | Cache 合规性 miter 验证顶层（Platform_C1/C2） |
| `two_copy_top_ct_ptci.v` | CPU_C2 PTCI 验证顶层（sticky_addr → allow_gnt_diff） |
| `two_copy_top_ct_ptci_c1_v2.v` | CPU_C1 PTCI 验证顶层（sticky_req → allow_gnt_diff） |
| `two_copy_top_ct_cache_r.v` | NoFwd + Regular Cache 组合验证 |
| `two_copy_top_ct_cache_s.v` | CPU + Cache-S 组合验证 |
| `two_copy_top_ct_ext_mem.v` | 无 PTCI 基线验证 |

**Sodor 相关（`src/sodor2/`）：**

| 文件 | 说明 |
|------|------|
| `two_copy_top_c1.sv` | Sodor CPU_C1 PTCI 验证顶层 |
| `two_copy_top_c2.sv` | Sodor CPU_C2 PTCI 验证顶层 |
| `two_copy_top_c3.sv` | Sodor CPU_C3 PTCI 验证顶层（区分程序/中断 PC 变化） |
| `interrupt_controller.v` | 简单内存映射中断控制器（wdata→int） |
| `intctrl_miter_verify.v` | 中断控制器合规性 miter（Platform_C2/C3） |

### 5.4 后续扩展方向

| 任务 | 说明 |
|------|------|
| C2/C3 修复验证 | Sodor + 安全中断控制器的组合验证 |
| RideCore + PTCI | 在更大的乱序超标量处理器上验证 |
| BOOM TileLink + PTCI | 扩展到 L2 cache 场景 |
| Counterexample 分析 | 详细分析攻击序列 |

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
