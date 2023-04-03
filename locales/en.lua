local Translations = {
    error = {
        notenoughmoney = "Not enough money",
        repossessed = "Your vehicle with plate %{plate} has been repossessed",
        vehinfo = "Couldn\'t get vehicle info",
        buyertoopoor = "The renter doesn\'t have enough money",
        norented = "You don't have any rented vehicles",
    },
    success = {
        rented = "Congratulations on your rental!",
    },
    menus = {
        rent_header = "Rent Vehicle",
        rent_txt = "Rent currently selected vehicle",
        vehHeader_header = "Vehicle Options",
        vehHeader_txt = "Interact with the current vehicle",
        rented_header = "Rented Vehicles",
        rented_txt = "Browse your rented vehicles",
        goback_header = "Go Back",
        veh_price = "Price: $",
        veh_platetxt = "Plate: ",
        submit_text = "Submit",
        swap_header = "Swap Vehicle",
        swap_txt = "Change currently selected vehicle",
        veh_rental_time = "Rental Time Remaining",
        rentalsubmit_rentalTime = "Rental Time - Min Hours: ",
        rentedTime_txt = "Time Left (Hours): "
    },
    general = {
        vehinteraction = "Vehicle Interaction",
        paymentduein = "Your vehicle rental expires within %{time} minutes",
    }
}

Lang = Lang or Locale:new({
    phrases = Translations,
    warnOnMissing = true
})
