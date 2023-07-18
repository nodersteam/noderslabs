import reward_information
import claim_rewards
import send_rewards
import vote_for_gas

def main_menu():
    while True:
        print("\nMain Menu:")
        print("1. Get Reward Information")
        print("2. Claim Rewards")
        print("3. Send Rewards to Address")
        print("4. Vote for Gas Price")
        print("0. Exit")

        choice = input("Enter your choice: ")

        if choice == "1":
            reward_information.get_reward_information()
        elif choice == "2":
            claim_rewards.claim_rewards()
        elif choice == "3":
            send_rewards.send_rewards_to_address()
        elif choice == "4":
            vote_for_gas.vote_for_gas_price()
        elif choice == "0":
            break
        else:
            print("Invalid choice. Please try again.")

# Run the main menu
if __name__ == "__main__":
    main_menu()
