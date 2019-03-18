#!/usr/bin/env ruby

require 'csv'

FILENAME = ARGV[0]
data = CSV.read(FILENAME)

state = :before_header
next_state = nil
current = {}
input = []

data.each do |row|
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
    current['date'] = Date.strptime(row[0][4..-1], " %m月 %e, %Y")
    state = :switch
  when :switch
    if row[0] == ' 朝食' || row[0] == ' 昼食' || row[0] == ' 夕食' || row[0] == ' 軽食/その他'
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
    current['situation'] = row[0].strip
    state = :day_food
  when :day_food
    if row[0].nil?
      state = :switch
      next
    end
    if row[0] == ' 朝食' || row[0] == ' 昼食' || row[0] == ' 夕食' || row[0] == ' 軽食/その他'
      state = :switch
      next
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
