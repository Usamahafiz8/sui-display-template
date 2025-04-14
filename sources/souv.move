module souv::souv {
    use sui::package;
    public struct SOUV has drop {}

    #[allow(lint(share_owned))]
    fun init(otw: SOUV, ctx: &mut TxContext) {
        let publisher = package::claim(otw, ctx);
        transfer::public_transfer(publisher, ctx.sender());
    }

}