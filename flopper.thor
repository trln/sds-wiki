#!/usr/bin/env ruby

require 'thor'
require 'json'
require 'yaml'
require 'csv'

def generate_csv_structure(attributes, persist, parent)
  attributes.each do |attr|
    persist[:csv] << %W(#{persist[:increment]} #{attr[:key]} #{attr[:type]} #{attr[:multi]} #{attr[:solr][:type]} #{attr[:solr][:attr].join('-')} #{attr[:ee]} #{attr[:desc]} #{parent})
    if attr[:type] == 'hash'
      generate_argot_array(attr[:attributes], persist, persist[:increment])
    end
    persist[:increment] = persist[:increment] + 1
  end
end


class Flopper < Thor

  ###############
  # yml to csv
  ###############
  desc "to_csv <input> <output>", "create a csv from argot.yml"

  def to_csv(input, output)
    puts "running"

    if File.exist?(input)

      argot = YAML.load_file(input)
      increment = 1

      persist = { :increment => 1, :csv => Array.new }
      generate_csv_structure(argot,persist,0)

      CSV.open(output, "wb") do |csv|
        csv << %w(id key type multi solr_type solr_attr ee desc parent)
        persist[:csv].each do |field|
          csv << field
        end
      end

    else
      puts "File does not exist"
    end
  end

  def generate_csv_structure(attributes, persist, parent=nil)
    attributes.each do |attr|
      puts persist

      add_array = Array.new
      add_array << persist[:increment]
      add_array << attr["key"] || ""
      add_array << attr["type"] || ""
      add_array << attr["multi"] || ""
      add_array << attr["indexed"] || ""
      add_array << attr["solr_attr"].join('-') || ""
      add_array << attr["ee"] || ""
      add_array << attr["desc"] || ""
      add_array << parent || 0

      persist[:csv] << add_array

      parent_state = persist[:increment]
      persist[:increment] += 1

      if attr["type"] == "hash"
        if attr["attributes"]
          generate_csv_structure(attr["attributes"], persist, parent_state)
        end
      end
    end
  end

end

