param(
    [string]$OutputPath = "assets/word_packs/runoob.json"
)

$ErrorActionPreference = "Stop"
$sourceUrl = "https://www.runoob.com/?lang=zh"
$html = (Invoke-WebRequest -UseBasicParsing -Uri $sourceUrl -TimeoutSec 60).Content
$pattern = '<a class="item-top[^"]*" href="([^"]+)"><h4>【学习\s*([^】]+)】</h4>[\s\S]*?<strong>.*?</strong></a>'
$matches = [regex]::Matches($html, $pattern)

if ($matches.Count -lt 100) {
    throw "教程目录解析异常，只找到 $($matches.Count) 项，已停止覆盖词包。"
}

$groups = @{
    "Python / 数据科学" = @("Python", "FastAPI", "Flask", "Django", "NumPy", "Pandas", "SciPy", "Matplotlib", "Dash", "Jupyter", "Pillow", "Julia", "R")
    "AI / 智能开发" = @("Vibe Coding", "Ollama", "TensorFlow", "PyTorch", "Scikit-learn", "OpenCV", "Selenium", "Playwright")
    "前端开发" = @("HTML", "CSS", "JavaScript", "DOM", "TypeScript", "AJAX", "JSON", "Tailwind", "Bootstrap", "Foundation", "Vue", "React", "Next.js", "Angular", "jQuery", "ECharts", "Chart.js", "Highcharts", "Google 地图", "SVG", "Font Awesome")
    "后端开发" = @("Node.js", "Electron", "PHP", "Java", "Go", "Rust", "Servlet", "JSP", "ASP", "AppML", "VBScript", "Swagger", "RESTful", "Docker", "Linux", "ZooKeeper")
    "数据库" = @("SQL", "MySQL", "PostgreSQL", "SQLite", "MongoDB", "Redis", "Memcached")
    "移动开发" = @("Android", "Flutter", "Ionic", "jQuery Mobile", "Swift", "Kotlin")
    "DevOps / 工程化" = @("Git", "SVN", "CMake", "Maven", "VS Code", "Obsidian", "PyCharm", "Eclipse", "Markdown", "PowerShell")
    "编程语言" = @("C", "C++", "C#", "Zig", "Scala", "Ruby", "Perl", "Lua", "Dart", "汇编语言", "Verilog")
    "网络与数据标准" = @("HTTP", "TCP/IP", "W3C", "XML", "DTD", "XSLT", "XPath", "XQuery", "XLink", "XPointer", "Schema", "XSL-FO", "Web Service", "WSDL", "SOAP", "RSS", "RDF")
    ".NET" = @("ASP.NET", "MVC", "Razor", "Web Forms", "Web Pages")
}

function Get-Group([string]$name) {
    foreach ($entry in $groups.GetEnumerator()) {
        foreach ($token in $entry.Value) {
            if ($name -eq $token -or ($token.Length -gt 2 -and $name -like "*$token*")) {
                return $entry.Key
            }
        }
    }
    return "计算机基础"
}

function Get-Difficulty([string]$name, [string]$group) {
    $low = @(
        "Python", "HTML", "HTML5", "CSS", "CSS3", "JavaScript", "HTML DOM",
        "AJAX", "JSON", "Bootstrap5", "Vue.js", "Vue3", "React", "jQuery",
        "Node.js", "PHP", "Java", "Go", "SQL", "MySQL", "SQLite", "Android",
        "Flutter", "Git", "VS Code", "Markdown", "HTTP", "XML"
    )
    if ($low -contains $name) { return "低" }
    if ($group -in @("AI / 智能开发", "网络与数据标准") -or
        $name -in @("Rust", "C++", "汇编语言", "Verilog", "ZooKeeper", "TensorFlow", "PyTorch")) {
        return "高"
    }
    return "中"
}

function Get-Texts([string]$name, [string]$group) {
    switch ($group) {
        "编程语言" {
            return @{
                definition = "$name 是一种编程语言或底层开发技术，用来按照明确规则描述数据与程序行为。"
                simple = "它是一种告诉计算机应该怎么做事情的表达方式。"
                analogy = "像人们用不同语言交流，开发者也用 $name 把步骤写给计算机看。"
                application = "可用于编写软件、处理数据或构建与其技术定位相符的系统。"
                mistake = "学会语法不等于会开发项目，还需要练习调试、设计和阅读真实代码。"
            }
        }
        "前端开发" {
            return @{
                definition = "$name 是前端开发相关的语言、框架或工具，用于构建网页的内容、样式与交互体验。"
                simple = "它帮助开发者制作用户在浏览器里能看到或操作的页面。"
                analogy = "做网页像装修商店，$name 是其中负责结构、装饰或互动的一套材料和工具。"
                application = "常用于制作网站界面、交互组件、数据图表或响应式页面。"
                mistake = "会使用框架不代表掌握了前端基础，HTML、CSS、JavaScript 和浏览器原理仍然重要。"
            }
        }
        "后端开发" {
            return @{
                definition = "$name 是服务端开发或部署相关技术，用于处理业务逻辑、请求、服务运行与系统协作。"
                simple = "它帮助网站或应用在用户看不见的后台完成工作。"
                analogy = "如果应用是一家餐厅，界面是前台，$name 就像后厨或后厨使用的工作系统。"
                application = "可用于开发接口、运行服务、处理任务、部署应用或管理服务器。"
                mistake = "后台开发不只是让程序运行，还必须考虑安全、并发、数据和故障处理。"
            }
        }
        "数据库" {
            return @{
                definition = "$name 是数据存储、查询或缓存相关技术，用于有组织地保存和读取应用数据。"
                simple = "它像一个会快速整理和查找资料的电子仓库。"
                analogy = "普通文件柜靠标签找资料，$name 则让计算机按规则快速存放和取出大量信息。"
                application = "常用于保存用户、订单、文章、配置、统计结果或高频缓存数据。"
                mistake = "数据库并不是装上就会自动高效，表结构、索引、查询和备份都需要设计。"
            }
        }
        "AI / 智能开发" {
            return @{
                definition = "$name 是人工智能、机器学习或自动化开发相关技术，用于训练模型、运行模型或自动完成任务。"
                simple = "它帮助计算机从数据中学习，或者自动完成原本需要人操作的工作。"
                analogy = "像给学徒准备教材、练习场和工具，$name 负责其中一种训练或执行工作。"
                application = "可用于数据建模、图像识别、自动化测试、本地模型运行或智能应用开发。"
                mistake = "使用 AI 工具不等于结果一定正确，数据质量、评估和人工检查仍不可省略。"
            }
        }
        "Python / 数据科学" {
            return @{
                definition = "$name 是 Python 或数据科学方向的语言、框架或工具，用于编程、分析数据与构建应用。"
                simple = "它帮助人们用代码处理资料、计算问题或制作程序。"
                analogy = "数据分析像做实验，$name 就是实验室里负责计算、整理或展示结果的一件工具。"
                application = "常用于数据清洗、科学计算、可视化、网站接口和自动化任务。"
                mistake = "调用现成函数不等于理解结果，还要知道输入数据、计算条件和适用范围。"
            }
        }
        "移动开发" {
            return @{
                definition = "$name 是移动应用开发相关的平台、语言或框架，用于构建手机和平板上的应用。"
                simple = "它是制作手机 App 时使用的平台或工具。"
                analogy = "开发 App 像盖不同规格的房子，$name 提供材料、施工规则或跨平台图纸。"
                application = "可用于开发 Android、iOS 或跨平台移动界面与功能。"
                mistake = "能在模拟器运行不代表已经适配真机，还要检查权限、性能、屏幕和系统版本。"
            }
        }
        "DevOps / 工程化" {
            return @{
                definition = "$name 是软件工程与开发效率相关的工具或格式，用于编写、构建、记录、协作或管理代码。"
                simple = "它帮助开发者更有条理地写代码、保存变化并完成项目。"
                analogy = "软件团队像工厂，$name 是工作台、说明书或流水线上的一种工具。"
                application = "常用于版本管理、项目构建、代码编辑、知识记录或自动化运维。"
                mistake = "工具只能改善流程，不能代替清晰的规范、代码质量和团队沟通。"
            }
        }
        "网络与数据标准" {
            return @{
                definition = "$name 是网络通信或结构化数据相关的协议与标准，用于规定信息如何表达、定位和传输。"
                simple = "它是一套让不同计算机能够看懂并交换信息的规则。"
                analogy = "像寄快递需要地址、包装和运输规则，$name 规定数据交流中的某个环节。"
                application = "常用于网页通信、接口交换、文档描述、数据查询或内容订阅。"
                mistake = "标准规定了格式和规则，但不会自动保证数据安全、内容正确或系统兼容。"
            }
        }
        ".NET" {
            return @{
                definition = "$name 是 .NET Web 开发体系中的框架、模式或页面技术，用于组织和生成 Web 应用。"
                simple = "它是微软 Web 开发工具箱中的一种做法或组件。"
                analogy = "像搭积木网站，$name 决定积木如何分工、组合或显示成页面。"
                application = "可用于构建企业网站、服务端页面、业务系统和分层 Web 应用。"
                mistake = "不同年代的 .NET 技术定位不同，不能只因名字相近就混为同一种开发方式。"
            }
        }
        default {
            return @{
                definition = "$name 是计算机技术学习中的一个主题，用于理解相关概念、规则与实际操作方法。"
                simple = "它是学习计算机时需要认识的一项技术或概念。"
                analogy = "像工具箱里的专用工具，$name 解决特定类型的问题。"
                application = "可用于建立计算机基础知识，并为相关开发或技术工作提供支持。"
                mistake = "看完教程不等于真正掌握，需要配合练习、调试和独立完成任务。"
            }
        }
    }
}

$seen = @{}
$sourceItems = [System.Collections.Generic.List[object]]::new()
foreach ($match in $matches) {
    $url = $match.Groups[1].Value.Trim()
    $name = [System.Net.WebUtility]::HtmlDecode($match.Groups[2].Value).Trim()
    if ($seen.ContainsKey($name)) { continue }
    $seen[$name] = $true
    $group = Get-Group $name
    $texts = Get-Texts $name $group
    $sourceItems.Add([ordered]@{
        sourceIndex = $sourceItems.Count + 1
        word = $name
        pinyin = ""
        field = "通用"
        difficulty = Get-Difficulty $name $group
        category = $group
        definition = $texts.definition
        simpleExplanation = $texts.simple
        lifeAnalogy = $texts.analogy
        practicalApplication = $texts.application
        commonMisconception = $texts.mistake
        sourceUrl = $url
    })
}

$tiers = @(
    @{ name = "菜鸟教程词汇包·一级（基础）"; code = 1; difficulties = @("低") },
    @{ name = "菜鸟教程词汇包·二级（进阶）"; code = 2; difficulties = @("低", "中") },
    @{ name = "菜鸟教程词汇包·三级（完整）"; code = 3; difficulties = @("低", "中", "高") }
)
$items = [System.Collections.Generic.List[object]]::new()
foreach ($tier in $tiers) {
    foreach ($source in $sourceItems) {
        if ($source.difficulty -notin $tier.difficulties) { continue }
        $items.Add([ordered]@{
            id = 3100000000 + ($tier.code * 10000) + $source.sourceIndex
            word = $source.word
            pinyin = $source.pinyin
            field = $source.field
            difficulty = $source.difficulty
            pack = $tier.name
            category = $source.category
            definition = $source.definition
            simpleExplanation = $source.simpleExplanation
            lifeAnalogy = $source.lifeAnalogy
            practicalApplication = $source.practicalApplication
            commonMisconception = $source.commonMisconception
            sourceUrl = $source.sourceUrl
        })
    }
}

$absoluteOutput = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\$OutputPath"))
$directory = Split-Path -Parent $absoluteOutput
[System.IO.Directory]::CreateDirectory($directory) | Out-Null
$json = $items | ConvertTo-Json -Depth 5
[System.IO.File]::WriteAllText($absoluteOutput, $json, [System.Text.UTF8Encoding]::new($false))
Write-Output "Found $($sourceItems.Count) tutorials; generated $($items.Count) cumulative entries: $absoluteOutput"

