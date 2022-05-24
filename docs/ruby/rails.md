### rails 关闭控制台输出颜色
1. 编辑 `~/.irbrc`
2. 添加 `IRB.conf[:USE_COLORIZE] = false`

### rails命令行打印格式化SQL
1. 编辑 `config/environments/production.rb` 文件
2. 设置日志级别 `config.log_level = :debug`

### rails CSV导出中文乱码修复
- 添加16进制BOM头
```ruby
CSV.open(filename,"a") do |csv|
       csv << ["\xEF\xBB\xBF九阴真经"]
end
```