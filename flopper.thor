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
  desc "to_csv <input> <output>", "create a csv from argot yaml file"

  def to_csv(input, output)

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

  ###############
  # yml to csv
  ###############
  desc "to_yml <input> <output>", "create a yml from an argot csv"

  def to_yml(input, output)

    if File.exist?(input)

      argot = Array.new

      argot_csv = CSV.read(input)

      argot_csv.delete_at(0)

      argot_csv.each do |field|
        argot_field = {
          "id" => field[0],
          "key" => field[1],
          "type" => field[2],
          "multi" => field[3] == "true" ? true : false,
          "indexed" => field[4] == "true" ? true : false,
          "solr_attr" => field[5] ? field[5].split(/-/) : nil,
          "ee" => field[6],
          "desc" => field[7]
        }
        if field[8] != "0"
          nest_argot_field(argot,argot_field,field[8])
        else
          argot << argot_field
        end
      end

      File.open(output, 'w') {|f| f.write argot.to_yaml }

    else
      puts "File does not exist"
    end
  end

  def nest_argot_field(argot, field, parent_id)

    argot.each do |a,idx|
      if a["id"] == parent_id
        if !a["attributes"].is_a?(Array)
          a["attributes"] = Array.new
        end
        a["attributes"] << field
      elsif a["attributes"].is_a?(Array)
        nest_argot_field(a["attributes"], field, parent_id)
      end

      #argot.delete_at(idx)
      #argot.insert(idx,a)
    end
  end

end

