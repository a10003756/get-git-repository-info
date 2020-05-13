require "./lib/class/command.rb"
require "net/http"

class GithubDataCollector
  
  def self.receive_github_http_response(argument)
    #githubからのレスポンスを取得
    uri = URI.parse("https://github.com/#{argument[0]}?tab=repositories")
    response = Net::HTTP.get_response(uri)
    if response.class == Net::HTTPNotFound
      puts "リポジトリが見つかりませんでした。"
      return
    elsif response.class == Net::HTTPOK
      self.get_user_repository_list(response)
    end
  end
  
  def self.get_user_repository_list(response)
    #responseからul = user-repositories-list部分だけを抽出
    /id="user-repositories-list"/ =~ response.body
     ok = $'
    %r!</ul>! =~ ok
    @all_repository_list = $`
    if @all_repository_list.class == NilClass
      puts "リポジトリが見つかりませんでした。"
      return
    elsif @all_repository_list.class == String
      self.get_public_repository_number(@all_repository_list)
      self.separate_every_repository    end
  end
  
  def self.separate_every_repository
    #user-repositories-listの中からlistごとに配列に入れる
    @separate_repository = @all_repository_list.split(/<li class=\"col-12/)
  end
  
  def self.get_public_repository_number(all_repository_list)
    #リポジトリに登録されている数を取得
    repository_list = all_repository_list.split(/col-10 col-lg-9 d-inline-block/)
    @public_repository_number = repository_list.size - 1
    puts "このアカウントは公開リポジトリが#{@public_repository_number}あります。"
    puts "リポジトリの情報を取得しますか？(y or n)"
    yes_or_no = STDIN.gets
    
    if yes_or_no == "y\n"
      self.output_public_repository_details((all_repository_list))
    else 
      return
    end 
  end
  
  def self.get_public_repository_names(all_repository_list)
    #リポジトリ名の取得
    @repository_names = []
    @public_repository_number.times do |number|
      %r!<a href=\"/#{ARGV[0]}/! =~ all_repository_list
      pre_repository_name = $'
      /"/ =~ pre_repository_name
      all_repository_list = pre_repository_name
      @repository_names << $`
    end
  end
  
  def self.get_public_repository_languages(all_repository_list)
    #主に使用されているプログラミング言語の取得
    @repository_languages = []
    self.separate_every_repository
    @public_repository_number.times do |number|
      %r!<span itemprop="programmingLanguage">! =~ @separate_repository[number+1]
      pre_repository_language = $'
      %r!</span>! =~ pre_repository_language
      all_repository_list = pre_repository_language
      if $` == nil
        @repository_languages << "プログラミング言語は使用されていません"
      elsif $` != nil
        @repository_languages << $`
      end
    end
  end
  
  def self.get_public_repository_list_edit_day(all_repository_list)
    #最終編集日の取得
    @repository_last_edit_day = []
    @public_repository_number.times do |number|
      /<relative-time datetime="/ =~ all_repository_list
      pre_repository_date = $'
      /Z"/ =~ pre_repository_date = pre_repository_date
      repository_last_edit_day = $`
      repository_last_edit_day_match = /(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)/.match(repository_last_edit_day)
      all_repository_list = pre_repository_date
      @repository_last_edit_day << "#{repository_last_edit_day_match[1]}年#{repository_last_edit_day_match[2]}月#{repository_last_edit_day_match[3]}日#{repository_last_edit_day_match[4]}時#{repository_last_edit_day_match[5]}分#{repository_last_edit_day_match[6]}秒に最終更新がされました。"
    end
  end
  
  def self.get_public_repository_description(all_repository_list)
    #説明文の取得
    @repository_descriptions = []
    self.separate_every_repository
    @public_repository_number.times do |number|
      %r!<p class="col-9 d-inline-block text-gray mb-2 pr-4" itemprop="description">! =~ @separate_repository[number+1]
      pre_repository_language = $'
      %r!</p>! =~ pre_repository_language
      if $` == nil
        @repository_descriptions << "説明は登録されていません。"
      elsif $` != nil
        @repository_descriptions << $`
      end
    end
    @repository_descriptions.each do |repository_description|
      repository_description.force_encoding("UTF-8")
    end
  end
  
  def self.get_public_repository_star_number(all_repository_list)
    #お気に入りにされている数を取得
    @repository_stars = []
    self.separate_every_repository
    @public_repository_number.times do |number|
      %r!d=\"M14 6l-4.9-.64L7 1 4.9 5.36 0 6l3.6 3.26L2.67 14 7 11.67 11.33 14l-.93-4.74L14 6z\"></path></svg>\n! =~ @separate_repository[number + 1]
      pre_repository_star = $'
      %r!</a>! =~ pre_repository_star
      @repository_stars << $`
    end
  end
  
  def self.create_public_repository_details_hash
    #リポジトリの詳細情報をハッシュにまとめる
    @repository_hash = {}

    @repository_details_array = [@repository_languages, @repository_last_edit_day, @repository_descriptions, @repository_stars].transpose
    @repository_array = [@repository_details_array].transpose
    @public_repository_number.times do |index|
      @repository_hash[@repository_names[index]] = @repository_array[index]
    end
  end
  
  def self.output_public_repository_details(all_repository_list)
    #出力情報をまとめている
    
    ##リポジトリ名と最終更新日(リポジトリが存在するなら必ずあるもの)
    self.get_public_repository_names(all_repository_list)
    self.get_public_repository_list_edit_day(all_repository_list)
    ##使用されている主な言語、説明文、お気に入り登録数(リポジトリによって存在しない場合があるもの)
    self.get_public_repository_languages(all_repository_list)
    self.get_public_repository_description(all_repository_list)
    self.get_public_repository_star_number(all_repository_list)
    
    self.create_public_repository_details_hash
    @public_repository_number.times do |index|
      output_text = <<~TEXT
      
        #{index + 1}
      
        リポジトリ名  :  #{@repository_hash.keys[index]}
        主な使用言語  :  #{@repository_hash.values[index][0][0]}
         最終更新日   :  #{@repository_hash.values[index][0][1]}
        お気に入り数  :  #{@repository_hash.values[index][0][3].to_i}
        #{@repository_hash.values[index][0][2]}
      
      --------------------------------------------------------------------------------------------
      TEXT
      puts output_text
    end
  end
  
end