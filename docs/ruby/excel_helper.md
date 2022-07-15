### 导出 csv和xlsx
```ruby
module ExcelHelper

    module_function

    def excel_export(filename, data, title = [], sheet_name = "")
        path = "/home/sunqi/disk150/rails_file"
        if !filename.start_with?(path)
            name = filename.split("/").last
            filename = path + "/" + name
        end
        book = Spreadsheet::Workbook.new
        sheet = book.create_worksheet
        sheet.name = sheet_name unless sheet_name.blank?
        index = 0
        if title != [] 
            index = 1
            sheet.row(0).replace(title)
        end
        data.each do |d|
            sheet.row(index).replace(d)
            index += 1
        end
        book.write(filename)
    end

    def self.excel_export(filename, data, title = [], sheet_name = "")
        path = "/home/sunqi/disk150/rails_file"
        if !filename.start_with?(path)
          name = filename.split("/").last
          filename = path + "/" + name
        end
        book = WriteXLSX.new(filename)
        sheet = book.add_worksheet(sheet_name.blank? ? "sheet1" : sheet_name)
        sheet.write_col("A1", [title]) unless title.blank?
        start = title.blank? ? "A1" : "A2"
        sheet.write_col(start, data)
        book.close; 0
    end
end
```