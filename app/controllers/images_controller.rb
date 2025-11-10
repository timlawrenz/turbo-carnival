class ImagesController < ApplicationController
  def show
    candidate = ImageCandidate.find(params[:id])

    if candidate.image_path.present? && File.exist?(candidate.image_path)
      send_file candidate.image_path, type: "image/png", disposition: "inline"
    else
      head :not_found
    end
  end
end
