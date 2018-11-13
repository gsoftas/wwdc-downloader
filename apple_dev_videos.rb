module DownloadController
  require 'nokogiri'
  require 'open-uri'
  require 'awesome_print'

  # Helper functions
  # 
  # Returns the result of opening the page that is passed to it
  def self.open_page(uri)
    Nokogiri::HTML(open(uri))
  end

  # Video class definition
  class Video
    attr_accessor :name, :page_url, :download_url, :section

    def initialize(name, page_url="", download_url="", section="")
      @name         = name 
      @page_url     = page_url 
      @download_url = download_url
      @section      = section
    end

    def describe
      puts "=========================================================="
      puts "Video Info:\n Name: #{@name}\n Page: #{@page_url}\n Download Link: #{@download_url}\n Section: #{@section}\n"
      puts "=========================================================="
    end

    def set_download_url
      video_download_url = DownloadController::open_page(@page_url).css('a').select {|a| a.text == 'HD Video'}
      
      # Checks for an HD Video link. If none exists, select will return an empty array 
      if video_download_url == []
        @download_url = ""
      else
        @download_url = video_download_url.first['href']
      end
    end

    # Returns true if video contains a valid download url
    def valid_download?
      @download_url != ""
    end

    # Returns the video filename removing the ?dl=1 suffix
    def filename
      @download_url.split("/").last.split("?").first
    end

    # Returns the file extension using the filename
    def file_extension
      filename.split(".").last
    end

    # Retuns the number for the video session
    def video_session
      filename.split("_").first
    end

    # Returns the a more readable version of the video filename 
    def proper_name
      "#{@name} (Session: #{video_session}).#{file_extension}"
    end
  end

  # Downloader class
  class Downloader
    def initialize
      @base_url       = ""
      @page_url       = ARGV[0] || "https://developer.apple.com/videos/wwdc2018/"
      @save_directory = ARGV[1] || "."
      @videos         = []
    end

    # Helper functions

    # Sets the base url for the video links
    def set_base_url
      uri = URI.parse(@page_url)
      @base_url = "#{uri.scheme}://#{uri.host}"
    end

    # Returns the 
    def get_videos_from_index_page
     
      ap "Getting index page links"

      DownloadController::open_page(@page_url).css(".collection-focus-group").each{ |c| 

        # Get the video section to name the folder
        section_name = c.css(".font-bold").text.strip ||= ""

        #Go through each of the section video links and create the video objects
        c.css("a").select {|link| link.text.strip != ''}.each {|link| 

     	v = Video.new(
            name = link.text.strip, 
            page_url = "#{@base_url}#{link['href']}",
            download_url = "", 
            section = section_name
          )
          
          ap "Scraping #{v.name}"
          v.set_download_url
          v.describe

          @videos << v
        }
      }
    end

    def download_files
      
      @videos.select{|video| video.valid_download? }.each {|v|
  
        # Download video file
        download_file(v)
      }

    end

    def download_file(video)
      # Check if the save directory exists and if not create it
      `mkdir "#{@save_directory}/#{video.section}"` unless Dir.exist?("#{@save_directory}/#{video.section}/")

      video.describe
      ap "Downloading file..."

      `wget -O "#{@save_directory}/#{video.section}/#{video.filename}" -N "#{video.download_url}" --show-progress`
      # `curl --url "#{video.download_url}" -o "#{@save_directory}/#{video.section}/#{video.filename}"`
    end

    def start
      set_base_url
      get_videos_from_index_page
      download_files
    end
    
  end
end

# Initialize a new Downloader object and start downloading the files
d = DownloadController::Downloader.new
d.start
