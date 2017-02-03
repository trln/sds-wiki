#!/usr/bin/env ruby

require 'thor'
require 'json'
require 'yaml'
require 'csv'

class MakerHelper

  def self.nest_argot_field(argot, field, parent_id)

    argot.each do |a,idx|
      if a["id"] == parent_id
        if !a["attributes"].is_a?(Array)
          a["attributes"] = Array.new
        end
        a["attributes"] << field
      elsif a["attributes"].is_a?(Array)
        MakerHelper::nest_argot_field(a["attributes"], field, parent_id)
      end

      #argot.delete_at(idx)
      #argot.insert(idx,a)
    end
  end

  def self.generate_csv_structure(attributes, persist, parent=nil)
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
          MakerHelper::generate_csv_structure(attr["attributes"], persist, parent_state)
        end
      end
    end
  end

  def self.create_solr_fields(collection, fields, expanding_key = nil)
    fields.each do |field|
      new_key = expanding_key ? expanding_key + "_" + field["key"] : field["key"]

      if new_key.end_with?("_value")
        new_key = new_key.sub("_value","")
      end

      if field["attributes"]
        MakerHelper::create_solr_fields(collection, field["attributes"], new_key)
      else
        if field["multi"]
          new_key = new_key + "_a"
        end

        if field["type"] == "gvo"
          field["indexed"] == true
          if field["solr_attr"]
            field["solr_attr"] << "stored"
          else
            field["solr_attr"] = ["stored"]
          end
        end

        if field["indexed"]
          collection[new_key] = {
            "type" => field["type"] == "gvo" ? "t" : field["type"],
            "attr" => field["solr_attr"]
          }
        end
      end
    end
  end

end


class Maker < Thor

  ###############
  # yml to csv
  ###############
  desc "to_csv <input> <output>", "create a csv from argot yaml file"

  def to_csv(input, output)

    if File.exist?(input)

      argot = YAML.load_file(input)
      increment = 1

      persist = { :increment => 1, :csv => Array.new }
      MakerHelper::generate_csv_structure(argot,persist,0)

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
          MakerHelper::nest_argot_field(argot,argot_field,field[8])
        else
          argot << argot_field
        end
      end

      File.open(output, 'w') {|f| f.write argot.to_yaml }

    else
      puts "File does not exist"
    end
  end

  

  ###############
  # yml to solr_fields config file
  ###############
  desc "to_solr_fields <input> <output>", "create a solr fields config file from argot yaml"

  def to_solr_fields(input, output)

    if File.exist?(input)

      argot = YAML.load_file(input)
      
      solr_fields = {}

      MakerHelper::create_solr_fields(solr_fields, argot)

      File.open(output, 'w') {|f| f.write solr_fields.to_yaml }

    else
      puts "File does not exist"
    end
  end

end

