#!/usr/bin/env ruby

require 'csv'

TEXT = {
  ja_JP: {
    breakfast: ' 朝食',
    lunch:  ' 昼食',
    dinner: ' 夕食',
    other: ' 軽食/その他',
    total: '合計',
    date_format: -> (str){begin Date.strptime(str[4..-1], " %m月 %e, %Y") rescue nil end}
  },
  en_US: {
    breakfast: ' Breakfast',
    lunch:  ' Lunch',
    dinner: ' Dinner',
    other: ' Snacks/Other',
    total: 'Total',
    date_format: -> (str){begin Date.strptime(str, "%a, %b %d, %Y") rescue nil end}
  }
}


FILENAME = ARGV[0]
data = CSV.read(FILENAME)

LANG = TEXT.find{|key, value| value[:date_format].call(data[1][1]) != nil}.first
_t = TEXT[LANG]

state = :before_header
next_state = nil
current = {}
input = []

data.each do |row|
#  STDERR.puts row.join(',')
  case state
  when :before_header
    next if row[0] != "# Report Details"
    state = :skip_single
    next_state = :header
  when :header
    headers = ["date", "situation", "name", "amount"] + row
#    p headers
    state = :skip_single
    next_state = :day_total
  when :skip_single
    state = next_state
  when :day_total
    break if row[0] == _t[:total]
    current['date'] = _t[:date_format].call(row[0])
    state = :switch
  when :switch
    if row[0] == _t[:breakfast] || row[0] == _t[:lunch] || row[0] == _t[:dinner] || row[0] == _t[:other]
      state = :day_situation
      redo
    end
    if row[0].nil? || row[0].empty?
      state = :day_total
      next
    end
    state = :day_food
    redo
  when :day_situation
    current['situation'] = TEXT[:ja_JP][TEXT[LANG].invert[row[0]]].strip
    state = :day_food
  when :day_food
    if row[0].nil? || row[0].empty?
      state = :day_total
      next
    end
    if row[0] == _t[:breakfast] || row[0] == _t[:lunch] || row[0] == _t[:dinner] || row[0] == _t[:other]
      state = :switch
      redo
    end
    current['food'] = row[0].strip
    current['cal'] = row[1].to_f
    current['fat'] = row[2].to_f
    current['carbo'] = row[4].to_f
    current['protein'] = row[7].to_f
    state = :day_amount
  when :day_amount
    current['amount'] = row[0].strip
    state = :switch
    #p current
    input << current.clone
  end
end

csv = CSV.new(STDOUT)
csv << input[0].keys
input.each do |row|
  csv << row.values
end
