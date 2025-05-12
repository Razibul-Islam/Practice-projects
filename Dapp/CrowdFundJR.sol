// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CrowdFundJR {
    struct Campaign {
        address creator;
        string title;
        string description;
        uint256 goal;
        uint256 deadline;
        uint256 pledged;
        bool claimed;
        mapping(address => uint256) contributions;
    }

    uint256 public campaignCount;
    mapping(uint256 => Campaign) public Campaigns;

    event CampaignCreated(uint256 id, address creator);
    event Pledged(uint256 id, address contributor, uint256 amount);
    event Unpledged(uint256 id, address contributor, uint256 amount);
    event FundsClaimed(uint256 id);
    event Refunded(uint256 id, address contributor, uint256 amount);

    modifier campaignExist(uint256 id) {
        require(id < campaignCount, "Campiagn does not exits");
        _;
    }

    modifier onlyCreator(uint256 id) {
        require(msg.sender == Campaigns[id].creator, "Not Campiagn creator");
        _;
    }

    modifier beforeDeadline(uint256 id) {
        require(block.timestamp < Campaigns[id].deadline, "Campaign has ended");
        _;
    }

    modifier afterDeadline(uint256 id) {
        require(
            block.timestamp >= Campaigns[id].deadline,
            "Campaigns still Active"
        );
        _;
    }

    function createCampaign(
        string memory title,
        string memory description,
        uint256 goal,
        uint256 duration
    ) external {
        require(goal > 0, "Goal must be greater than 0");
        require(duration > 0, "Duration must be greater than 0");

        Campaign storage camp = Campaigns[campaignCount];
        camp.creator = msg.sender;
        camp.title = title;
        camp.description = description;
        camp.goal = goal;
        camp.deadline = block.timestamp + duration;

        emit CampaignCreated(campaignCount, msg.sender);
        campaignCount++;
    }

    function pledge(uint256 id)
        external
        payable
        campaignExist(id)
        beforeDeadline(id)
    {
        require(msg.value > 0, "Must pledge more than 0");

        Campaign storage campaign = Campaigns[id];
        campaign.pledged += msg.value;
        campaign.contributions[msg.sender] += msg.value;

        emit Pledged(id, msg.sender, msg.value);
    }

    function unpledge(uint256 id, uint256 amount)
        external
        campaignExist(id)
        beforeDeadline(id)
    {
        Campaign storage campaign = Campaigns[id];
        uint256 contributed = campaign.contributions[msg.sender];
        require(amount > 0 && contributed >= amount, "Invalid amount");

        campaign.pledged -= amount;
        campaign.contributions[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit Unpledged(id, msg.sender, amount);
    }

    function claimFunds(uint256 id)
        external
        campaignExist(id)
        onlyCreator(id)
        afterDeadline(id)
    {
        Campaign storage campaign = Campaigns[id];
        require(campaign.pledged > campaign.goal, "Funding goal not yet");
        require(!campaign.claimed, "Funds already claimed");

        campaign.claimed = true;
        payable(campaign.creator).transfer(campaign.pledged);

        emit FundsClaimed(id);
    }

    function refund(uint256 id) external campaignExist(id) afterDeadline(id) {
        Campaign storage campaign = Campaigns[id];
        require(campaign.pledged < campaign.goal, "Funding goal was met");
        uint256 contributed = campaign.contributions[msg.sender];
        require(contributed > 0, "No contribution to refund");
        campaign.contributions[msg.sender] = 0;
        payable(msg.sender).transfer(contributed);
        emit Refunded(id, msg.sender, contributed);
    }

    function getContribution(uint256 id, address contributor)
        external
        view
        campaignExist(id)
        returns (uint256)
    {
        return Campaigns[id].contributions[contributor];
    }

    function getCampaign(uint256 id)
        external
        view
        campaignExist(id)
        returns (
            address creator,
            string memory title,
            string memory description,
            uint256 goal,
            uint256 deadline,
            uint256 pledged,
            bool claimed
        )
    {
        Campaign storage c = Campaigns[id];

        return (
            c.creator,
            c.title,
            c.description,
            c.goal,
            c.deadline,
            c.pledged,
            c.claimed
        );
    }
}
